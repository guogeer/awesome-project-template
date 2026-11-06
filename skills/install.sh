#!/usr/bin/env bash
# 把本仓库 skills/ 安装到指定项目，让 AI 编码代理真正发现并生效。
#
# 用法:
#   bash skills/install.sh                          # 安装到本仓库根的 .codebuddy/skills/（复制）
#   bash skills/install.sh --project ~/some-repo    # 安装到其他项目
#   bash skills/install.sh --tools codebuddy,codex,kilo
#   bash skills/install.sh --link                   # 用相对软链代替复制（源仓库内改一处即生效）
#   bash skills/install.sh --only auto-commit-push  # 只装指定技能
#
# 说明:
# - CodeBuddy 只扫描 <项目>/.codebuddy/skills/，其他路径下的技能不可见；
#   codex/kilo 等按各自约定目录放置，多工具多副本需要各自安装。
# - _template 是骨架模板，不会被安装。
# - 复制模式下升级技能 = 重新跑一遍本脚本（幂等覆盖，多余旧文件不删）。
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
src="$repo_root/skills"
project="$repo_root"
tools="codebuddy"
mode="copy"
only=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) project="$2"; shift 2 ;;
    --tools)   tools="$2"; shift 2 ;;
    --link)    mode="link"; shift ;;
    --only)    only="$2"; shift 2 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

declare -A tool_dir=(
  [codebuddy]="$project/.codebuddy/skills"
  [codex]="$project/.codex/skills"
  [kilo]="$project/.kilo/skills"
)

installed=0
for name in "$src"/*/; do
  name="$(basename "$name")"
  [[ "$name" != "_template" && -f "$src/$name/SKILL.md" ]] || continue
  [[ -z "$only" || ",$only," == *",$name,"* ]] || continue
  for t in ${tools//,/ }; do
    [[ -n "${tool_dir[$t]:-}" ]] || { echo "未知工具: $t" >&2; exit 2; }
    dst="${tool_dir[$t]}/$name"
    mkdir -p "$(dirname "$dst")"
    rm -rf "$dst"
    if [[ "$mode" == "link" ]]; then
      ln -s "$(realpath --relative-to="$(dirname "$dst")" "$src/$name")" "$dst"
    else
      cp -a "$src/$name" "$dst"
    fi
    echo "[$t] $name -> $dst"
    installed=$((installed + 1))
  done
done

[[ "$installed" -gt 0 ]] || { echo "没有安装任何技能（检查 --only 拼写）" >&2; exit 1; }
echo "完成：共 $installed 个技能副本（mode=$mode）。修改技能后：复制模式需重跑本脚本，软链模式即时生效。"
