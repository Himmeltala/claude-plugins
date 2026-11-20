#!/usr/bin/env bash
# PreToolUse 闸门，管两件事：
#   1. 提交信息必须是一行，且带规定的类型前缀
#   2. 工作副本落后于服务器、或存在未解决冲突时，拦下 `svn commit`
#
# 除此之外不管：回滚、历史等用法不干预。
#
# 判定依据是一次 `svn status --xml -u`，两个元素都是实测确认的：
#   item="conflicted"  有未解决冲突，含树冲突
#   <repos-status>     工作副本落后于服务器。本地 add / delete / 改内容都不产生该元素，
#                      所以拿它当落后判据不会误拦正常提交。
#
# 服务器不可达时退化成只查本地冲突，冲突判定不依赖网络。
#
# 任何异常一律放行：不是 Bash 调用、JSON 解析失败、目标不是工作副本、svn 报错。
#
# 依赖 python3 或 jq 任一个来解析钩子输入；两者都没有时静默放行。

set -uo pipefail

# shellcheck source=guard-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/guard-common.sh"

# 找出命令行里真正执行 svn 提交的那一段，找到就打印出来。
# 先按 ; && || | 切段，再看每段是否以 svn 开头且带 commit / ci 参数——
# 这样 `echo "svn commit"`、注释里的字样、日志里搜 commit 都不会误判。
find_commit_segment() {
  local cmd="$1" seg trimmed
  while IFS= read -r seg; do
    trimmed="${seg#"${seg%%[![:space:]]*}"}"
    case "$trimmed" in
      svn[[:space:]]*)
        if [[ "$trimmed" =~ [[:space:]](commit|ci)([[:space:]]|$) ]]; then
          printf '%s' "$trimmed"
          return 0
        fi
        ;;
    esac
  done < <(printf '%s\n' "$cmd" | sed 's/&&/\n/g; s/||/\n/g; s/|/\n/g; s/;/\n/g')
  return 1
}

# 提交目标：命令行里第一个「存在且是工作副本」的路径参数，没有就用当前目录。
# 跳过 -m / -F 等选项的值，否则提交信息里的词可能被当成路径。
resolve_target() {
  local seg="$1" cwd="$2" tok skip=0
  seg="${seg#svn}"
  for tok in $seg; do
    if [ "$skip" = 1 ]; then skip=0; continue; fi
    case "$tok" in
      -*=*) continue ;;
      -m | --message | -F | --file | --targets | --changelist | --depth) skip=1; continue ;;
      -*) continue ;;
      *)
        if [ -e "$tok" ] && svn info --non-interactive "$tok" >/dev/null 2>&1; then
          printf '%s' "$tok"
          return 0
        fi
        ;;
    esac
  done
  printf '%s' "$cwd"
}

report_and_block() {
  local target="$1" conflicted="$2" outdated="$3" offline="$4"
  local -a reasons=() steps=()

  [ -n "$outdated" ] && reasons+=("工作副本落后于服务器，直接提交会撞 out-of-date")
  [ -n "$conflicted" ] && reasons+=("存在未解决的冲突（标记 C）")

  steps+=("svn update")
  if [ -n "$conflicted" ]; then
    steps+=("打开每个冲突文件，清干净 <<<<<<< / ======= / >>>>>>> 三种标记")
    steps+=("svn resolve --accept=working <冲突文件>")
  fi
  steps+=("重新执行刚才的 svn commit")

  {
    echo "提交被拦下：先更新、解决冲突，再提交。"
    echo
    echo "工作副本：$target"
    [ -n "$offline" ] && echo "（服务器不可达，只做了本地冲突检查）"
    echo
    echo "原因：${reasons[*]}"
    echo
    echo "按顺序做："
    local i=1
    for s in "${steps[@]}"; do
      echo "  $i. $s"
      i=$((i + 1))
    done
    if [ -n "$conflicted" ]; then
      echo
      echo "冲突文件用 svn status 看，标 C 的就是。--accept=working 不会自动清掉冲突标记，"
      echo "resolve 之后必须打开文件确认标记已删干净，否则标记会随提交进版本库。"
    fi
  } >&2
  exit 2
}

main() {
  local cmd cwd seg target xml offline=""
  hook_input || exit 0
  cwd="${HOOK_FIELDS[1]}"
  cmd="${HOOK_FIELDS[2]}"

  seg=$(find_commit_segment "$cmd") || exit 0

  check_commit_message "$seg"

  target=$(resolve_target "$seg" "$cwd")
  [ -n "$target" ] || exit 0
  svn info --non-interactive "$target" >/dev/null 2>&1 || exit 0

  # 先带 -u 查落后；服务器不可达时退化成只查本地冲突。
  xml=$(svn status --xml --non-interactive -u -- "$target" 2>/dev/null) || xml=""
  if [ -z "$xml" ]; then
    xml=$(svn status --xml --non-interactive -- "$target" 2>/dev/null) || exit 0
    offline=1
  fi

  local conflicted="" outdated=""
  grep -q 'item="conflicted"' <<<"$xml" && conflicted=1
  grep -q '<repos-status' <<<"$xml" && outdated=1
  [ -n "$conflicted$outdated" ] || exit 0

  report_and_block "$target" "$conflicted" "$outdated" "$offline"
}

main
