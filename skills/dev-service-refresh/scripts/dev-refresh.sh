#!/usr/bin/env bash
# 任务收尾刷新本地 dev 服务：让刚改完的代码立刻在本地服务生效（见 ../SKILL.md）。
#
# 做的事：
#   BACKENDS 里的 uvicorn --reload 服务 → touch 触发文件让它自己重启 worker（轮询健康检查确认）
#   WEB_PROBE_PORT（vite HMR 等）       → 只探测并提示，热更由前端工具自己完成
#   FLUTTER_PORT                        → 发 SIGUSR1（热重载）/ SIGUSR2（热重启，--full）
#
# 不做的事：不重启进程、不杀进程、不替用户后台起服务、不碰远程环境。
# 服务没起 / 监听进程不是预期程序时只打印「跳过」，退出码恒为 0（收尾的尽力动作，不阻断提交）。
#
# 用法（在仓库根执行）：
#   bash skills/dev-service-refresh/scripts/dev-refresh.sh
#   bash skills/dev-service-refresh/scripts/dev-refresh.sh --full       # App 端走热重启
#   bash skills/dev-service-refresh/scripts/dev-refresh.sh --api-only   # 只刷后端
#   bash skills/dev-service-refresh/scripts/dev-refresh.sh --web-only   # 只刷页面/App
#   bash skills/dev-service-refresh/scripts/dev-refresh.sh --dry-run    # 只打印计划
#
# ★ 复制到项目后必须改下面的「项目配置段」。

# ───────────────────────── 项目配置段 ─────────────────────────
# 后端列表："名称:端口:触发文件(相对仓库根):日志名"，触发文件是被 uvicorn --reload 监视的模块
BACKENDS=(
  "app-api:${APP_API_PORT:-12100}:app/api/src/<package>/app.py:app-api"
  # "admin-api:${ADMIN_API_PORT:-12101}:admin/api/src/<package>/app.py:admin-api"
)
# 与 BACKENDS 一一对应的后端目录（相对仓库根），用于 .env* 陈旧性检查
BACKEND_DIRS=(
  "app/api"
  # "admin/api"
)
FLUTTER_PORT="${FLUTTER_PORT:-12103}"       # Flutter dev 端口，不跑 Flutter 就留一个不存在的端口
WEB_PROBE_PORT="${WEB_PROBE_PORT:-12102}"   # 前端 HMR 端口（只探测）
HEALTH_PATH="/healthz"                      # 后端健康检查路径
DEV_START_CMD="./tool/dev.sh"               # 用户手动起服务的命令（仅用于提示）
LOG_DIR=".dev-logs"                         # dev 日志目录（仅用于提示）
# ───────────────────────────────────────────────────────────────

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || REPO_ROOT="$(pwd)"

FULL="0"
DRY="0"
ONLY_API="0"
ONLY_WEB="0"

usage() {
  awk 'NR>1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --full) FULL="1"; shift ;;
    --dry-run) DRY="1"; shift ;;
    --api-only) ONLY_API="1"; shift ;;
    --web-only) ONLY_WEB="1"; shift ;;
    -h | --help) usage ;;
    *) echo "未知参数: $1（用 --help 看用法）" >&2; exit 0 ;;
  esac
done

log() { printf '%s\n' "$*"; }

# 端口上的监听进程（拿不到就空串，例如端口没人监听）
port_pid() {
  local port="$1"
  ss -lptnH "sport = :$port" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | head -1
}

proc_cmd() {
  tr '\0' ' ' <"/proc/$1/cmdline" 2>/dev/null | sed 's/ *$//' || true
}

# 进程启动时刻（epoch 秒）：用来判断 .env* 是不是比进程还新（那样配置没生效）
proc_started_at() {
  local pid="$1" elapsed
  elapsed="$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ')"
  [[ -n "$elapsed" ]] || return 0
  echo $(( $(date +%s) - elapsed ))
}

healthz() {
  curl -fsS -m 2 -o /dev/null "http://127.0.0.1:$1$HEALTH_PATH" 2>/dev/null
}

# .env* 比进程新 = 改了配置但没重启，重载也不会带上（文件监听忽略点开头路径）
warn_stale_env() {
  local api_dir="$1" pid="$2" started file mtime
  started="$(proc_started_at "$pid")"
  [[ -n "$started" ]] || return 0
  for file in "$api_dir/.env" "$api_dir/.env.development" "$api_dir/.env.test"; do
    [[ -f "$file" ]] || continue
    mtime="$(stat -c %Y "$file" 2>/dev/null)"
    [[ -n "$mtime" ]] || continue
    if (( mtime > started )); then
      log "      ⚠ ${file#$REPO_ROOT/} 比进程新：配置改动不会随重载生效，需要重启该服务"
    fi
  done
}

refresh_backend() {
  local name="$1" port="$2" trigger="$3" logname="$4" api_dir="$5"
  local pid ppid i
  pid="$(port_pid "$port")"
  if [[ -z "$pid" ]]; then
    log "  $name($port)：未运行（需要的话跑 $DEV_START_CMD）"
    return 0
  fi

  ppid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
  if [[ -z "$ppid" ]] || [[ "$(proc_cmd "$ppid")" != *uvicorn* ]]; then
    log "  $name($port)：监听进程的父进程不是 uvicorn --reload，跳过（要生效请重启该服务）"
    warn_stale_env "$api_dir" "$pid"
    return 0
  fi

  if [[ ! -f "$trigger" ]]; then
    log "  $name($port)：找不到触发文件 ${trigger#$REPO_ROOT/}，跳过（检查配置段的触发文件路径）"
    return 0
  fi

  if [[ "$DRY" == "1" ]]; then
    log "  $name($port)：将 touch ${trigger#$REPO_ROOT/} 触发热重载（worker pid $pid）"
    warn_stale_env "$api_dir" "$pid"
    return 0
  fi

  # touch 只改 mtime、不改内容：文件监听收到 modified 事件，uvicorn 重启 worker；
  # 仓库内容不变，git status 仍然是干净的。
  touch "$trigger"
  # 等重载真的完成（先给 worker 退出 + 重新启动留时间，再轮询健康检查）
  sleep 2
  for ((i = 0; i < 36; i++)); do
    if healthz "$port"; then
      log "  $name($port)：已重载，$HEALTH_PATH OK"
      warn_stale_env "$api_dir" "$pid"
      return 0
    fi
    sleep 1
  done
  log "  $name($port)：已触发重载，但 $HEALTH_PATH 20s 内没起来（看 $LOG_DIR/${logname}.log）"
}

refresh_flutter() {
  local pid cmd sig how
  pid="$(port_pid "$FLUTTER_PORT")"
  if [[ -z "$pid" ]]; then
    log "  flutter($FLUTTER_PORT)：未运行（需要的话跑 $DEV_START_CMD）"
    return 0
  fi

  cmd="$(proc_cmd "$pid")"
  # 只在确认是 flutter 进程时才发信号：SIGUSR1 是 kill 的默认终止信号，发错进程直接弄死它
  if [[ "$cmd" != *flutter* ]]; then
    log "  flutter($FLUTTER_PORT)：监听进程不是 flutter（${cmd:-读不到命令行}），跳过"
    return 0
  fi

  sig="USR1"
  how="热重载"
  if [[ "$FULL" == "1" ]]; then
    sig="USR2"
    how="热重启"
  fi

  if [[ "$DRY" == "1" ]]; then
    log "  flutter($FLUTTER_PORT)：将给 pid $pid 发 SIG$sig（$how）"
    return 0
  fi

  if kill -s "$sig" "$pid" 2>/dev/null; then
    log "  flutter($FLUTTER_PORT)：已触发$how（pid $pid）"
    [[ "$FULL" == "1" ]] && log "      改了 pubspec.yaml / 依赖的话热重启也不够，需要重跑 $DEV_START_CMD"
  else
    log "  flutter($FLUTTER_PORT)：发信号失败（pid $pid 可能刚退出）"
  fi
}

probe_web() {
  local pid
  pid="$(port_pid "$WEB_PROBE_PORT")"
  if [[ -n "$pid" ]]; then
    log "  web($WEB_PROBE_PORT)：在运行（HMR 自己热更，无需动作）"
  else
    log "  web($WEB_PROBE_PORT)：未运行（需要的话跑 $DEV_START_CMD）"
  fi
}

if ! command -v ss >/dev/null 2>&1; then
  log "==> 缺少 ss（iproute2），无法探测本机端口，跳过刷新"
  exit 0
fi

log "==> 刷新本地 dev 服务（$REPO_ROOT）"
[[ "$DRY" == "1" ]] && log "    （--dry-run：只打印计划，不实际触发）"

if [[ "$ONLY_WEB" == "0" ]]; then
  idx=0
  for entry in "${BACKENDS[@]}"; do
    IFS=':' read -r name port trigger logname <<<"$entry"
    refresh_backend "$name" "$port" "$REPO_ROOT/$trigger" "$logname" "${BACKEND_DIRS[$idx]:-$REPO_ROOT}"
    idx=$((idx + 1))
  done
fi

if [[ "$ONLY_API" == "0" ]]; then
  probe_web
  refresh_flutter
fi

log "==> 完成（服务没起的行是「未运行」，需要时跑 $DEV_START_CMD 一次起全部）"
exit 0
