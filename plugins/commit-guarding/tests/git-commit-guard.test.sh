#!/usr/bin/env bash
# git-commit-guard.sh 的验收测试。每次跑都重建 /tmp/gitguard 下的临时仓库，
# 造出「落后远端」「与远端分叉」「本地领先」等真实状态，不碰任何真实工作副本。
#
# 用法（在插件根目录下）：bash tests/git-commit-guard.test.sh hooks/scripts/git-commit-guard.sh

set -uo pipefail

GUARD="${1:?用法: bash tests/git-commit-guard.test.sh <git-commit-guard.sh 路径>}"
ROOT=/tmp/gitguard
ORIGIN="$ROOT/origin.git"
RA="$ROOT/repo-a"
RB="$ROOT/repo-b"
RC="$ROOT/repo-c"
PLAIN="$ROOT/not-a-repo"

pass=0
fail=0

payload() {
  python3 -c '
import json, sys
print(json.dumps({
    "session_id": "test",
    "hook_event_name": "PreToolUse",
    "tool_name": sys.argv[1],
    "cwd": sys.argv[2],
    "tool_input": {"command": sys.argv[3]},
}))' "$1" "$2" "$3"
}

call_hook() {
  printf '%s' "$2" | bash "$GUARD" 2>"$ROOT/.err"
  got=$?
  ERR=$(cat "$ROOT/.err")
}

allow() {
  call_hook "$1" "$2"
  if [ "$got" = 0 ]; then
    pass=$((pass + 1)); printf 'ok   %-42s 放行\n' "$1"
  else
    fail=$((fail + 1)); printf 'FAIL %-42s 应当放行，实际 exit=%s\n     stderr: %s\n' "$1" "$got" "$ERR"
  fi
}

block() {
  call_hook "$1" "$2"
  if [ "$got" != 2 ]; then
    fail=$((fail + 1)); printf 'FAIL %-42s 应当拦下，实际 exit=%s\n     stderr: %s\n' "$1" "$got" "$ERR"
  elif [[ "$ERR" != *"$3"* ]]; then
    fail=$((fail + 1)); printf 'FAIL %-42s 已拦下但提示未含「%s」\n     stderr: %s\n' "$1" "$3" "$ERR"
  else
    pass=$((pass + 1)); printf 'ok   %-42s 拦下，提示含「%s」\n' "$1" "$3"
  fi
}

block_without() {
  call_hook "$1" "$2"
  if [ "$got" != 2 ]; then
    fail=$((fail + 1)); printf 'FAIL %-42s 应当拦下，实际 exit=%s\n     stderr: %s\n' "$1" "$got" "$ERR"
  elif [[ "$ERR" == *"$3"* ]]; then
    fail=$((fail + 1)); printf 'FAIL %-42s 提示里不该出现「%s」\n     stderr: %s\n' "$1" "$3" "$ERR"
  else
    pass=$((pass + 1)); printf 'ok   %-42s 拦下，提示不含「%s」\n' "$1" "$3"
  fi
}

must() {
  if ! "$@" >/dev/null 2>&1; then
    printf 'FIXTURE 建库失败，测试作废：%s\n' "$*" >&2
    exit 1
  fi
}

gitq() { git -C "$1" "${@:2}"; }

rm -rf "$ROOT"
mkdir -p "$ROOT" "$PLAIN"
must git init -q --bare -b main "$ORIGIN"
must git clone -q "$ORIGIN" "$RA"
must git -C "$RA" config user.email t@t
must git -C "$RA" config user.name t
printf 'alpha\nbeta\ngamma\n' >"$RA/f.txt"
must gitq "$RA" add f.txt
must gitq "$RA" commit -m "初始文件"
must gitq "$RA" push -q -u origin main
must git clone -q "$ORIGIN" "$RB"
must git -C "$RB" config user.email t@t
must git -C "$RB" config user.name t
must git clone -q "$ORIGIN" "$RC"
must git -C "$RC" config user.email t@t
must git -C "$RC" config user.name t

[ "$(gitq "$ORIGIN" rev-list --count main)" -ge 1 ] || {
  printf 'FIXTURE 版本库历史不对，测试作废\n' >&2; exit 1; }
[ "$(git -C "$RA" rev-parse --abbrev-ref '@{u}')" = "origin/main" ] || {
  printf 'FIXTURE repo-a 上游不对，测试作废\n' >&2; exit 1; }

echo "== 放行分支 =="
allow "非 git 命令"                 "$(payload Bash "$RA" 'ls -la')"
allow "只读 git status"             "$(payload Bash "$RA" 'git status')"
allow "信息里出现 commit 字样"       "$(payload Bash "$RA" 'echo "git commit -m x"')"
allow "git commit-tree 不是提交"     "$(payload Bash "$RA" 'git commit-tree HEAD^{tree} -m x')"
allow "tool_name 不是 Bash"         "$(payload Read "$RA" 'git commit -m "x"')"
allow "畸形 JSON"                   '{ not json'
allow "空输入"                      ''
allow "非仓库目录"                  "$(payload Bash "$PLAIN" 'git commit -m "chore: x"')"
allow "干净且最新的提交"             "$(payload Bash "$RA" 'git commit -m "chore: 测试"')"
allow "干净且最新的推送"             "$(payload Bash "$RA" 'git push')"
allow "合规格提交信息"               "$(payload Bash "$RA" 'git commit -m "feat: 新增接口"')"
allow "带 scope 与 ! 的类型"          "$(payload Bash "$RA" 'git commit -m "feat(api)!: 新增接口"')"
allow "--amend --no-edit 沿用上一条"  "$(payload Bash "$RA" 'git commit --amend --no-edit')"
printf 'fix: 单行信息\n' >"$ROOT/msg-ok.txt"
allow "-F 文件单行合规"              "$(payload Bash "$RA" "git commit -F $ROOT/msg-ok.txt")"

echo
echo "== 提交信息不合规：拦下 =="
block "缺少类型前缀"                "$(payload Bash "$RA" 'git commit -m "修正接口"')" "类型前缀"
block "前缀不在规定列表"             "$(payload Bash "$RA" 'git commit -m "bugfix: 修正接口"')" "类型前缀"
block "类型后缺冒号"                "$(payload Bash "$RA" 'git commit -m "feat 新增接口"')" "类型前缀"
block "两处 -m 拼成多行"             "$(payload Bash "$RA" 'git commit -m "feat: a" -m "b"')" "单行"
block "引号跨行"                    "$(payload Bash "$RA" 'git commit -m "feat: 第一行
第二行"')" "单行"
printf 'feat: a\n\n正文\n' >"$ROOT/msg-multi.txt"
block "-F 文件多行"                 "$(payload Bash "$RA" "git commit -F $ROOT/msg-multi.txt")" "单行"
block "-F 走标准输入"               "$(payload Bash "$RA" 'git commit -F -')" "单行"
block "裸 git commit"               "$(payload Bash "$RA" 'git commit')" "没有给提交信息"

echo
echo "== detached HEAD 不再管 =="
must gitq "$RA" checkout -q --detach
allow "游离 HEAD 提交"              "$(payload Bash "$RA" 'git commit -m "chore: 测试"')"
must gitq "$RA" checkout -q main

echo
echo "== 本地领先远端：放行 =="
printf 'alpha\nBETA_B\n' >"$RB/f.txt"
must gitq "$RB" commit -qam "B 改 beta 行"
allow "领先远端时提交"              "$(payload Bash "$RB" 'git commit -m "chore: 测试"')"
allow "领先远端时推送"              "$(payload Bash "$RB" 'git push')"

echo
echo "== 与远端分叉：拦下 =="
printf 'alpha\nBETA_A\n' >"$RA/f.txt"
must gitq "$RA" commit -qam "A 改 beta 行"
must gitq "$RA" push -q
block "分叉时提交"                  "$(payload Bash "$RB" 'git commit -m "chore: 测试"')" "git pull --rebase"
block "分叉时推送"                  "$(payload Bash "$RB" 'git push')" "git pull --rebase"
block "分叉，git -C 指定仓库"        "$(payload Bash "$ROOT" "git -C $RB commit -m \"chore: 测试\"")" "git pull --rebase"

echo
echo "== 落后远端：拦下 =="
must gitq "$RB" fetch -q origin
must gitq "$RB" reset -q --hard origin/main
printf 'alpha\nBETA_A2\n' >"$RA/f.txt"
must gitq "$RA" commit -qam "A 再改 beta 行"
must gitq "$RA" push -q
block "落后远端提交"                "$(payload Bash "$RB" 'git commit -m "chore: 测试"')" "git pull --rebase"
block "落后远端推送"                "$(payload Bash "$RB" 'git push')" "git pull --rebase"
block_without "工作区干净时不提暂存"  "$(payload Bash "$RB" 'git commit -m "chore: 测试"')" "git stash"
block "分号串联的提交"              "$(payload Bash "$RB" 'cd /tmp && git commit -m "chore: 测试"')" "git pull --rebase"
block "&& 串联的提交"               "$(payload Bash "$RB" 'git status && git commit -m "chore: 测试"')" "git pull --rebase"

echo
echo "== 落后且有未提交改动：提示先暂存 =="
printf 'alpha\nBETA_LOCAL\n' >"$RB/f.txt"
must gitq "$RB" add f.txt
block "落后且工作区有改动"           "$(payload Bash "$RB" 'git commit -m "chore: 测试"')" "git stash"
must gitq "$RB" reset -q --hard

echo
echo "== 拉取之后：放行 =="
must gitq "$RB" pull -q --rebase origin main
allow "拉取后提交"                  "$(payload Bash "$RB" 'git commit -m "chore: 测试"')"
allow "拉取后推送"                  "$(payload Bash "$RB" 'git push')"

echo
echo "== 远端不可达：跳过落后判定，放行 =="
must gitq "$RC" remote set-url origin "$ROOT/no-such-remote.git"
printf 'alpha\nGAMMA_C\n' >"$RC/f.txt"
must gitq "$RC" commit -qam "C 改 gamma 行"
allow "远端不可达时不误拦"           "$(payload Bash "$RC" 'git commit -m "chore: 测试"')"
allow "远端不可达时推送不误拦"        "$(payload Bash "$RC" 'git push')"

echo
printf '通过 %d，失败 %d\n' "$pass" "$fail"
[ "$fail" = 0 ]
