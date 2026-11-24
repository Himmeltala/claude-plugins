#!/usr/bin/env bash
# 在后台概括当前会话，把标题写进状态文件的 pending 字段，等下一次提问由钩子回填。
#
# 由 session-title.sh 脱离父进程拉起，用完即退。整个流程只有三步：从 transcript 取一段
# 对话、交给一次无状态的 claude -p 调用、清理返回值。
#
# --no-session-persistence：这次调用不该在 ~/.claude/projects 下留下会话记录。
# 工作目录切到插件自己的数据目录：换个空目录，项目级的 CLAUDE.md 与设置就进不来，
# 概括只看对话本身。
# CLAUDE_SESSION_TITLE_WORKER=1 传给子进程，让子进程里的同一个钩子立刻退掉，不会递归。
#
# 任何异常一律静默退出并留着旧标题：标题是锦上添花，不值得弹错误。

set -uo pipefail

# shellcheck source=hook-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/hook-common.sh"

export CLAUDE_SESSION_TITLE_WORKER=1

session_id="${1:-}"
transcript="${2:-}"
project="${3:-}"
[ -n "$session_id" ] && [ -f "$transcript" ] || exit 0

state="$DATA_DIR/${session_id}.state"

# 上一个 worker 还在跑时直接退，避免同一会话并发两路模型调用
running=$(state_get "$state" running)
case "$running" in '' | *[!0-9]*) running=0 ;; esac
now=$(date +%s)
[ $((now - running)) -lt 180 ] && [ "$running" -ne 0 ] && exit 0

state_set "$state" running "$now"
trap 'state_set "$state" running 0' EXIT

prompt=$(python3 "$SCRIPT_DIR/build-prompt.py" "$transcript" 2>/dev/null) || exit 0
[ -n "$prompt" ] || exit 0

model_args=()
[ -n "${SESSION_NAMING_MODEL:-}" ] && model_args=(--model "$SESSION_NAMING_MODEL")

command -v claude >/dev/null 2>&1 || exit 0
if command -v timeout >/dev/null 2>&1; then
  runner=(timeout 90 claude)
else
  runner=(claude)
fi

raw=$(cd "$DATA_DIR" && "${runner[@]}" -p "$prompt" --no-session-persistence \
  --output-format text "${model_args[@]}" </dev/null 2>/dev/null) || exit 0
[ -n "$raw" ] || exit 0

title=$(printf '%s' "$raw" | python3 "$SCRIPT_DIR/clean-title.py" 2>/dev/null) || exit 0
[ -n "$title" ] || exit 0

# 存进去的就是最终标题，前缀一起算。钩子回填、手动改名判据都拿这同一个值比对。
title=$(compose_title "$project" "$title")

# 与当前标题相同就不写，免得每一轮都白改一次
applied=$(state_get "$state" applied)
[ "$title" = "$applied" ] && exit 0

state_set "$state" pending "$title"
