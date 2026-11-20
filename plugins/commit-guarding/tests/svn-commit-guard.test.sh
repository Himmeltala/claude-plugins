#!/usr/bin/env bash
# svn-commit-guard.sh 的验收测试。每次跑都重建 /tmp/svnguard 下的临时版本库，
# 造出「落后服务器」「冲突未解决」等真实状态，不碰任何真实工作副本。
#
# 用法（在插件根目录下）：bash tests/svn-commit-guard.test.sh hooks/scripts/svn-commit-guard.sh

set -uo pipefail

GUARD="${1:?用法: bash tests/svn-commit-guard.test.sh <svn-commit-guard.sh 路径>}"
ROOT=/tmp/svnguard
R="$ROOT/repo"
WA="$ROOT/wc-a"
WB="$ROOT/wc-b"
PLAIN="$ROOT/not-a-wc"

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

must() {
  if ! "$@" >/dev/null; then
    printf 'FIXTURE 建库失败，测试作废：%s\n' "$*" >&2
    exit 1
  fi
}

rm -rf "$ROOT"
mkdir -p "$ROOT" "$PLAIN"
must svnadmin create "$R"
must svn mkdir --non-interactive -m "初始化主干" "file://$R/trunk"
must svn checkout --non-interactive "file://$R/trunk" "$WA"
printf 'alpha\nbeta\ngamma\n' > "$WA/f.txt"
must svn add --non-interactive "$WA/f.txt"
must svn commit --non-interactive -m "初始文件" "$WA/f.txt"
must svn checkout --non-interactive "file://$R/trunk" "$WB"

[ "$(svn log --non-interactive -q "file://$R/trunk" | grep -c '^r')" -ge 2 ] || {
  printf 'FIXTURE 版本库历史不对，测试作废\n' >&2; exit 1; }
[ "$(svn info --show-item url "$WA")" = "file://$R/trunk" ] || {
  printf 'FIXTURE wc-a 指向不对，测试作废\n' >&2; exit 1; }

echo "== 放行分支 =="
allow "非 svn 命令"                "$(payload Bash "$WA" 'ls -la')"
allow "只读 svn status"            "$(payload Bash "$WA" 'svn status')"
allow "信息里出现 commit 字样"      "$(payload Bash "$WA" 'echo "svn commit -m x"')"
allow "maven 构建"                 "$(payload Bash "$WA" 'mvn clean install -DskipTests')"
allow "tool_name 不是 Bash"        "$(payload Read "$WA" 'svn commit -m "x"')"
allow "畸形 JSON"                  '{ not json'
allow "空输入"                     ''
allow "非工作副本目录"             "$(payload Bash "$PLAIN" 'svn commit -m "chore: x"')"
allow "干净且最新的提交"            "$(payload Bash "$WA" 'svn commit -m "chore: 测试"')"
allow "合规格提交信息"              "$(payload Bash "$WA" 'svn commit -m "feat: 新增接口"')"
allow "带 scope 的合法类型"          "$(payload Bash "$WA" 'svn commit -m "fix(api): 修复接口"')"
printf 'fix: 单行信息\n' > "$ROOT/msg-ok.txt"
allow "-F 文件单行合规"             "$(payload Bash "$WA" "svn commit -F $ROOT/msg-ok.txt")"

echo
echo "== 提交信息不合规：拦下 =="
block "缺少类型前缀"                "$(payload Bash "$WA" 'svn commit -m "修正接口"')" "类型前缀"
block "前缀不在规定列表"             "$(payload Bash "$WA" 'svn commit -m "bugfix: 修正接口"')" "类型前缀"
block "类型后缺冒号"                "$(payload Bash "$WA" 'svn commit -m "feat 新增接口"')" "类型前缀"
block "两处 -m 拼成多行"             "$(payload Bash "$WA" 'svn commit -m "feat: a" -m "b"')" "单行"
block "引号跨行"                    "$(payload Bash "$WA" 'svn commit -m "feat: 第一行
第二行"')" "单行"
printf 'feat: a\n\n正文\n' > "$ROOT/msg-multi.txt"
block "-F 文件多行"                 "$(payload Bash "$WA" "svn commit -F $ROOT/msg-multi.txt")" "单行"
block "没有给信息"                  "$(payload Bash "$WA" 'svn commit')" "没有给提交信息"

echo
echo "== 落后服务器：拦下 =="
printf 'alpha\nBETA_A\ngamma\n' > "$WA/f.txt"
must svn commit --non-interactive -m "A 改 beta 行" "$WA/f.txt"
block "落后服务器提交"             "$(payload Bash "$WB" 'svn commit -m "chore: 测试"')" "svn update"
block "落后服务器，显式路径"        "$(payload Bash "$ROOT" "svn commit -m \"chore: 测试\" $WB")" "svn update"
block "svn ci 简写"                "$(payload Bash "$WB" 'svn ci -m "chore: 测试"')" "svn update"
block "分号后的 svn commit"         "$(payload Bash "$WB" 'cd /tmp && svn commit -m "chore: 测试"')" "svn update"
block "&& 串联的 svn commit"        "$(payload Bash "$WB" 'svn status && svn commit -m "chore: 测试"')" "svn update"

echo
echo "== update 之后：放行 =="
svn update --non-interactive "$WB" >/dev/null 2>&1 || true
allow "更新后提交"                 "$(payload Bash "$WB" 'svn commit -m "chore: 测试"')"

echo
echo "== 冲突：拦下 =="
printf 'alpha\nBETA_AA\ngamma\n' > "$WA/f.txt"
must svn commit --non-interactive -m "A 再改 beta 行" "$WA/f.txt"
printf 'alpha\nBETA_BB\ngamma\n' > "$WB/f.txt"
svn update --non-interactive "$WB" >/dev/null 2>&1 || true
block "冲突未解决提交"             "$(payload Bash "$WB" 'svn commit -m "chore: 测试"')" "冲突"
block "冲突未解决，显式路径"        "$(payload Bash "$ROOT" "svn commit -m \"chore: 测试\" $WB/f.txt")" "冲突"

echo
echo "== resolve 之后：放行 =="
printf 'alpha\nBETA_MERGED\ngamma\n' > "$WB/f.txt"
must svn resolve --non-interactive --accept=working "$WB/f.txt"
allow "解决冲突后提交"             "$(payload Bash "$WB" 'svn commit -m "chore: 测试"')"

echo
printf '通过 %d，失败 %d\n' "$pass" "$fail"
[ "$fail" = 0 ]
