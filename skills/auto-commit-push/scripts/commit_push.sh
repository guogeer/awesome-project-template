#!/usr/bin/env bash
# 在当前 git 仓库内提交改动并推送到 origin（通用版，复制到项目后直接可用）。
# 默认只提交显式列出的路径，避免把别的会话 / 任务的改动一起带走；确需全量提交加 --all。
# 用法: commit_push.sh -m "<提交信息>" <path...> [--all] [--no-push] [--dry-run] [--allow-sensitive]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "错误: 当前不在 git 仓库内" >&2
  exit 1
}
cd "$REPO_ROOT"

MESSAGE=""
NO_PUSH=0
DRY_RUN=0
ALLOW_SENSITIVE=0
ALL=0
PATHS=()

usage() {
  cat <<'EOF'
用法: commit_push.sh -m "<提交信息>" [path...] [选项]

选项:
  -m, --message <msg>   提交信息（必填）
  <path>...             只提交这些路径（默认，推荐）
      --all             提交工作区全部改动（含与本次任务无关的，慎用）
      --no-push         只提交，不推送
      --dry-run         只打印将要执行的动作
      --allow-sensitive 放行被判定为敏感的文件
  -h, --help            显示帮助
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m | --message)
      MESSAGE="${2:-}"
      shift 2
      ;;
    --all) ALL=1; shift ;;
    --no-push) NO_PUSH=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --allow-sensitive) ALLOW_SENSITIVE=1; shift ;;
    -h | --help) usage; exit 0 ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do PATHS+=("$1"); shift; done
      ;;
    *) PATHS+=("$1"); shift ;;
  esac
done

if [[ -z "$MESSAGE" ]]; then
  echo "错误: 缺少提交信息 (-m)" >&2
  usage >&2
  exit 2
fi

BRANCH="$(git branch --show-current)"
if [[ -z "$BRANCH" ]]; then
  echo "错误: 处于 detached HEAD，拒绝提交" >&2
  exit 1
fi

REMOTE="origin"
if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
  echo "错误: 未配置 remote $REMOTE" >&2
  exit 1
fi

# 收集待提交路径：
# --all 取工作区全部改动（可能混入别的会话 / 任务的改动）；默认只取显式列出的路径
CHANGED=()
if [[ "$ALL" -eq 1 ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    CHANGED+=("${line:3}")
  done < <(git status --porcelain)
else
  if [[ ${#PATHS[@]} -eq 0 ]]; then
    echo "错误: 未指定提交路径——默认只提交本次任务相关的改动，不带走别的会话 / 任务的改动。" >&2
    echo "      当前工作区改动如下，请挑出本次任务的路径再提交：" >&2
    git status --porcelain >&2
    echo "      用法: $0 -m \"<提交信息>\" <path...>；确需全量提交请显式加 --all。" >&2
    exit 2
  fi
  for p in "${PATHS[@]}"; do
    if [[ ! -e "$p" ]] && ! git ls-files --error-unmatch "$p" >/dev/null 2>&1; then
      echo "错误: 路径不存在且未被 git 跟踪: $p" >&2
      exit 1
    fi
  done
  CHANGED=("${PATHS[@]}")
fi

if [[ ${#CHANGED[@]} -eq 0 ]]; then
  echo "没有需要提交的改动，跳过。"
  exit 0
fi

# 敏感文件拦截：.env 实体 / 私钥 / keystore（.env.example 等模板不拦）
SENSITIVE_RE='(^|/)\.env$|\.(pem|key|p12|pfx|keystore|jks)$|(^|/)id_(rsa|ed25519|ecdsa)$'
check_sensitive() {
  [[ "$ALLOW_SENSITIVE" -eq 1 ]] && return 0
  local f
  for f in "$@"; do
    if [[ "$f" =~ $SENSITIVE_RE ]]; then
      echo "错误: 疑似敏感文件，已拦截: $f" >&2
      echo "      确认可入仓后可加 --allow-sensitive，或先补 .gitignore" >&2
      return 1
    fi
  done
}
check_sensitive "${CHANGED[@]}"

echo "仓库: $REPO_ROOT"
echo "分支: $BRANCH -> $REMOTE"
echo "提交信息: $MESSAGE"
echo "待提交:"
printf '  %s\n' "${CHANGED[@]}"

if [[ "$DRY_RUN" -eq 1 ]]; then
  if [[ "$ALL" -eq 1 ]]; then
    echo "[dry-run] 将执行: git add -A && git commit -m \"$MESSAGE\""
  else
    echo "[dry-run] 将执行: git add -A -- ${PATHS[*]} && git commit -m \"$MESSAGE\" -- ${PATHS[*]}"
  fi
  if [[ "$NO_PUSH" -eq 0 ]]; then
    echo "[dry-run] 将执行: git push $REMOTE $BRANCH"
  fi
  exit 0
fi

if [[ "$ALL" -eq 1 ]]; then
  git add -A
else
  # 用 -A 才能把指定路径下的删除也 stage 进去
  git add -A -- "${PATHS[@]}"
fi

if git diff --cached --quiet; then
  echo "错误: 暂存区为空，未产生提交（目标路径可能已被 .gitignore 或改动已提交）" >&2
  exit 1
fi

# 对实际进入暂存区的文件再校验一次（指定目录时会展开出具体文件）
mapfile -t STAGED < <(git diff --cached --name-only)
check_sensitive "${STAGED[@]}"

if [[ "$ALL" -eq 1 ]]; then
  git commit -m "$MESSAGE"
else
  # 显式带 pathspec：别的会话可能已经把改动 stage 过，不带进本次提交
  git commit -m "$MESSAGE" -- "${PATHS[@]}"
fi
COMMIT_HASH="$(git rev-parse --short HEAD)"
echo "已提交: $COMMIT_HASH $(git log -1 --format=%s)"

if [[ "$NO_PUSH" -eq 1 ]]; then
  echo "已按 --no-push 跳过推送。"
  exit 0
fi

if ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  git push -u "$REMOTE" "$BRANCH"
else
  git push "$REMOTE" "$BRANCH"
fi

echo "已推送: $REMOTE/$BRANCH @ $(git rev-parse --short HEAD)"
