#!/usr/bin/env bash
# PreToolUse 闸门，管两件事：
#   1. 提交信息必须是一行，且带规定的类型前缀
#   2. 本地落后或分叉于远端时，拦下 `git commit` 与 `git push`
#
# 除此之外不管：分支、撤销、回滚等用法不干预。
#
# 落后判定用 `git ls-remote` 而不是 `git fetch`：ls-remote 只读远端引用，不改本地
# 任何状态，钩子不动工作副本这条底线不破。远端不可达（离线、无凭据）或没有上游时
# 判定不了，放行。
#
# 任何异常一律放行：不是 Bash 调用、JSON 解析失败、目标不是 git 仓库、git 报错。
#
# 依赖 python3 或 jq 任一个来解析钩子输入；两者都没有时静默放行。

set -uo pipefail

# shellcheck source=guard-common.sh
source "$(dirname "${BASH_SOURCE[0]}")/guard-common.sh"

# 这一段是不是 git commit / git push 调用。跳过全局选项与它们的取值
# （-C 目录、-c 配置、--git-dir 等），再看剩下的第一个非选项词。
git_subcommand() {
  local -a toks=()
  read -r -a toks <<<"$1"
  [ "${#toks[@]}" -gt 0 ] || return 1
  case "${toks[0]}" in
    git | */git) ;;
    *) return 1 ;;
  esac

  local i=1 skip=0 t
  while [ "$i" -lt "${#toks[@]}" ]; do
    t="${toks[$i]}"
    if [ "$skip" = 1 ]; then
      skip=0
      i=$((i + 1))
      continue
    fi
    case "$t" in
      -c | -C | --git-dir | --work-tree | --namespace | --exec-path | --config-env | --attr-source)
        skip=1
        ;;
      -*) ;;
      commit | push)
        printf '%s' "$t"
        return 0
        ;;
      *) return 1 ;;
    esac
    i=$((i + 1))
  done
  return 1
}

# 按 ; && || | 把命令行切成几段，用 NUL 分隔输出。引号里的分隔符不算，
# 换行同理：引号没闭合时换行属于信息本身，不能切成两段。
split_segments() {
  printf '%s\n' "$1" | awk '
    {
      n = length($0)
      for (i = 1; i <= n; i++) {
        c = substr($0, i, 1)
        if (c == "\"" && !sq) { dq = !dq; seg = seg c; continue }
        if (c == "'"'"'" && !dq) { sq = !sq; seg = seg c; continue }
        if (!dq && !sq) {
          if (substr($0, i, 2) == "&&" || substr($0, i, 2) == "||") {
            printf "%s%c", seg, 0; seg = ""; i++; continue
          }
          if (c == ";" || c == "|") { printf "%s%c", seg, 0; seg = ""; continue }
        }
        seg = seg c
      }
      if (dq || sq) { seg = seg "\n" } else { printf "%s%c", seg, 0; seg = "" }
    }
    END { if (seg != "") printf "%s%c", seg, 0 }
  '
}

# 找出命令行里真正执行提交或推送的那一段，输出「动作<空格>片段」。
find_action_segment() {
  local -a segs=()
  local seg trimmed action
  mapfile -d '' -t segs < <(split_segments "$1")
  for seg in "${segs[@]}"; do
    trimmed="${seg#"${seg%%[![:space:]]*}"}"
    action=$(git_subcommand "$trimmed") || continue
    printf '%s %s' "$action" "$trimmed"
    return 0
  done
  return 1
}

# 目标目录：`git -C <目录>` 里最后一个取值，没有就用当前目录。
resolve_repo_dir() {
  local seg="$1" cwd="$2" prev="" tok dir=""
  for tok in $seg; do
    [ "$prev" = "-C" ] && dir="$tok"
    prev="$tok"
  done
  printf '%s' "${dir:-$cwd}"
}

report_block() {
  local action="$1" repo="$2" detail="$3" dirty="$4"
  local verb next
  if [ "$action" = push ]; then verb="推送"; next="重新执行刚才的 git push"
  else verb="提交"; next="重新执行刚才的 git commit"
  fi
  {
    echo "${verb}被拦下：先拉最新、解决冲突，再${verb}。"
    echo
    echo "仓库：$repo"
    [ -n "$detail" ] && echo "$detail"
    echo
    echo "按顺序做："
    if [ "$dirty" = 1 ]; then
      echo "  1. git stash push -u —— 工作区有未提交改动，不先收起来，变基会被 git 拒绝"
      echo "  2. git fetch origin"
      echo "  3. git pull --rebase"
      echo "  4. 有冲突就打开文件清干净 <<<<<<< / ======= / >>>>>>> 三种标记，git add 之后 git rebase --continue"
      echo "  5. git stash pop —— 把改动放回来"
      echo "  6. $next"
    else
      echo "  1. git fetch origin"
      echo "  2. git pull --rebase"
      echo "  3. 有冲突就打开文件清干净 <<<<<<< / ======= / >>>>>>> 三种标记，git add 之后 git rebase --continue"
      echo "  4. $next"
    fi
  } >&2
  exit 2
}

check_repo_state() {
  local action="$1" repo="$2" gitdir branch local_sha remote_sha up remote rbranch dirty=""

  gitdir=$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null) ||
    gitdir=$(git -C "$repo" rev-parse --git-dir 2>/dev/null) || return 0
  [ -n "$gitdir" ] || return 0

  # detached HEAD 不管；那是用户自己的选择
  branch=$(git -C "$repo" symbolic-ref --short -q HEAD 2>/dev/null) || return 0
  [ -n "$branch" ] || return 0

  # 上游没配（新分支第一次提交）时无从比较，放行
  up=$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null) || return 0
  [ -n "$up" ] || return 0
  remote="${up%%/*}"
  rbranch="${up#*/}"
  [ "$remote" != "$up" ] || return 0

  local_sha=$(git -C "$repo" rev-parse HEAD 2>/dev/null) || return 0
  [ -n "$local_sha" ] || return 0

  # ls-remote 只读远端引用，不动本地状态；网络慢时给它设个上限
  if command -v timeout >/dev/null 2>&1; then
    remote_sha=$(timeout 10 git -C "$repo" ls-remote --heads "$remote" "refs/heads/$rbranch" 2>/dev/null | awk 'NR==1{print $1}')
  else
    remote_sha=$(git -C "$repo" ls-remote --heads "$remote" "refs/heads/$rbranch" 2>/dev/null | awk 'NR==1{print $1}')
  fi
  # 远端不可达或分支在远端还不存在：判定不了，放行
  [ -n "$remote_sha" ] || return 0
  [ "$remote_sha" = "$local_sha" ] && return 0

  # 工作区有未提交改动时，变基会被 git 拒绝，提示里要先给暂存这一步
  [ -n "$(git -C "$repo" status --porcelain 2>/dev/null | head -n 1)" ] && dirty=1

  if git -C "$repo" merge-base --is-ancestor "$local_sha" "$remote_sha" 2>/dev/null; then
    report_block "$action" "$repo" "远端 $remote/$rbranch 上有本地还没有的提交" "$dirty"
  fi
  # 本地领先：这些提交本来就等着推上去，放行
  git -C "$repo" merge-base --is-ancestor "$remote_sha" "$local_sha" 2>/dev/null && return 0
  report_block "$action" "$repo" "远端 $remote/$rbranch 与本地各自有新提交" "$dirty"
}

main() {
  local cmd cwd found action seg repo
  hook_input || exit 0
  cwd="${HOOK_FIELDS[1]}"
  cmd="${HOOK_FIELDS[2]}"

  found=$(find_action_segment "$cmd") || exit 0
  action="${found%% *}"
  seg="${found#* }"

  [ "$action" = commit ] && check_commit_message "$seg"

  repo=$(resolve_repo_dir "$seg" "$cwd")
  [ -n "$repo" ] || exit 0
  [ -d "$repo" ] || exit 0
  check_repo_state "$action" "$repo"
}

main
