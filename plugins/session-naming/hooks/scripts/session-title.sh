#!/usr/bin/env bash
# UserPromptSubmit 钩子：把上一次在后台生成好的标题回填给会话，顺手决定要不要再生成一次。
#
# 为什么分前后台：生成标题要起一次模型调用，实测三秒上下。钩子是用户按下回车之后
# 同步执行的，让它等这三秒就是把延迟直接加在提问上。所以这里只做三件事——读状态、
# 回填、派活，都在毫秒级完成；调模型的活儿交给脱离父进程的 title-worker.sh，
# 下一次提问自然就用上了新标题。代价是标题滞后一轮，这是拿延迟换来的。
#
# 为什么不用 custom-title 记录有没有来判断用户手动改过名：钩子设置的标题，Claude Code
# 同样写成 custom-title，两条记录在 transcript 里无法区分。只能拿文件里最后一条
# custom-title 和自己上次回填的值比，不相等才算手动改，改了以后本会话永久停手。
# 首次运行、缓存又被清过的情况下，旧标题会被当成手动设置——宁可停手也不覆盖用户。
#
# 只有用户亲自提交的消息才排期：loop、定时唤醒、peer 消息这类注入轮次不触发重命名。
#
# 任何异常一律放行：钩子只做锦上添花，自身出故障时绝不能堵住用户的提问。

set -uo pipefail

# shellcheck source=hook-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/hook-common.sh"

main() {
  # 后台 worker 跑的是 claude -p，会重新触发本钩子，靠这个环境变量在第一步退掉
  [ "${CLAUDE_SESSION_TITLE_WORKER:-}" = "1" ] && exit 0
  [ "${SESSION_NAMING_OFF:-}" = "1" ] && exit 0

  local raw
  raw=$(cat)
  [ -n "$raw" ] || exit 0

  local -a input=()
  mapfile -d '' -t input < <(parse_input "$raw")
  [ "${#input[@]}" -eq 6 ] || exit 0

  local session_id="${input[1]}" transcript="${input[2]}" source="${input[4]}"
  [ -n "$session_id" ] || exit 0

  local state="$DATA_DIR/${session_id}.state"
  [ "$(state_get "$state" manual)" = "1" ] && exit 0

  local applied pending seen
  applied=$(state_get "$state" applied)
  pending=$(state_get "$state" pending)

  # 用户用 /rename 改过名就停手，本会话不再碰标题
  seen=$(last_custom_title "$transcript")
  if [ -n "$seen" ] && [ "$seen" != "$applied" ] && [ "$seen" != "$pending" ]; then
    state_set "$state" manual 1
    exit 0
  fi

  local title=""
  if [ -n "$pending" ]; then
    title="$pending"
    state_set "$state" applied "$pending"
    state_set "$state" pending ""
  elif [ -n "$applied" ]; then
    title="$applied"
  fi
  [ -n "$title" ] && emit_title "$title"

  [ "${source:-user}" = "user" ] || exit 0
  [ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

  # 计数到间隔才重新生成；还没有任何标题时第一轮就排期，别等用户问够四轮
  local counter last_run now due=0
  counter=$(state_get "$state" counter)
  case "$counter" in '' | *[!0-9]*) counter=0 ;; esac
  counter=$((counter + 1))

  last_run=$(state_get "$state" last_run)
  case "$last_run" in '' | *[!0-9]*) last_run=0 ;; esac
  now=$(date +%s)

  if [ -z "$applied" ] && [ -z "$pending" ] && [ "$counter" -ge 1 ]; then
    due=1
  elif [ "$counter" -ge "$INTERVAL" ]; then
    due=1
  fi
  # 两次生成之间至少隔两分钟，短会话不会反复起进程
  if [ "$due" = 1 ] && [ $((now - last_run)) -lt 120 ]; then
    due=0
  fi

  if [ "$due" != 1 ]; then
    state_set "$state" counter "$counter"
    exit 0
  fi

  state_set "$state" counter 0
  state_set "$state" last_run "$now"

  # 脱离父进程：钩子退出后 worker 继续跑，输出全部丢弃，不污染钩子的 stdout。
  # 重定向要加在整个子 shell 上：只写在 nohup 那一层的话，包着 `cd &&` 的那层子 shell
  # 仍握着钩子的 stdout 管道，调用方要等 worker 跑完才读到 EOF，等于同步执行。
  ( cd "$DATA_DIR" && exec env CLAUDE_SESSION_TITLE_WORKER=1 \
    nohup bash "$SCRIPT_DIR/title-worker.sh" "$session_id" "$transcript" ) \
    >/dev/null 2>&1 </dev/null &

  exit 0
}

main
