#!/usr/bin/env bash
# svn 与 git 两份闸门共用的部分：钩子输入解析、提交信息取值与校验、提示输出。
#
# 判据不在这里：svn 的落后与冲突读 `svn status --xml -u`，git 的落后读 `git ls-remote`，
# 没有可复用的判定，各自留在自己的脚本里。
#
# 任何异常一律放行：闸门只拦确定坏的情况，自身出故障时绝不能堵住提交。

# 输出 tool_name、cwd、command，用 NUL 分隔。bash 变量存不了 NUL，所以走 mapfile。
parse_input() {
  local raw="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(1)
ti = d.get("tool_input") or {}
sys.stdout.write("%s\0%s\0%s" % (
    d.get("tool_name") or "", d.get("cwd") or "", ti.get("command") or ""))
' <<<"$raw" 2>/dev/null
  elif command -v jq >/dev/null 2>&1; then
    jq -j '[.tool_name // "", .cwd // "", .tool_input.command // ""] | join("\u0000")' \
      <<<"$raw" 2>/dev/null
  else
    return 1
  fi
}

# 读钩子输入，把 tool_name、cwd、command 三段写进全局数组 HOOK_FIELDS。
# cwd 不在这里消化：svn 闸门的 resolve_target 要用它。
# 不是 Bash 调用、缺命令、JSON 解析失败时返回 1。
hook_input() {
  local raw
  raw=$(cat)
  [ -n "$raw" ] || return 1

  HOOK_FIELDS=()
  mapfile -d '' -t HOOK_FIELDS < <(parse_input "$raw")
  [ "${#HOOK_FIELDS[@]}" -eq 3 ] || return 1

  [ "${HOOK_FIELDS[0]}" = "Bash" ] || return 1
  [ -n "${HOOK_FIELDS[2]}" ] || return 1
}

# ---------- 提交信息：一行，且带指定类型前缀 ----------

# 按 shell 参数解析一段提交命令，输出 NUL 分隔的「类型 值」记录。
# 类型：ready（解析成功）、msg（-m 的值）、file（-F 的值）、source（沿用已有信息）。
# 用 shlex 解析，路径或信息正文里出现 "-m" 字样不会被误当成选项。
# python3 不可用时输出为空，调用方据此跳过信息校验，不误拦。
extract_commit_args() {
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$1" <<'PY'
import shlex, sys

try:
    toks = shlex.split(sys.argv[1])
except ValueError:
    sys.exit(0)

out = []
out += ["ready", "1"]
i = 0
while i < len(toks):
    t = toks[i]
    if t in ("-m", "--message"):
        if i + 1 < len(toks):
            out += ["msg", toks[i + 1]]
            i += 2
        else:
            i += 1
        continue
    if t.startswith("--message="):
        out += ["msg", t.split("=", 1)[1]]
        i += 1
        continue
    if t in ("-F", "--file"):
        if i + 1 < len(toks):
            out += ["file", toks[i + 1]]
            i += 2
        else:
            i += 1
        continue
    if t.startswith("--file="):
        out += ["file", t.split("=", 1)[1]]
        i += 1
        continue
    if t in ("-C", "--reuse-message", "--template") or t.startswith(("-C", "--reuse-message=", "--fixup=", "--squash=", "--template=")) or t == "--no-edit":
        out += ["source", "1"]
        i += 1
        continue
    # 短选项组：-am "信息"、-m信息、-am信息、-F文件
    if t.startswith("-") and not t.startswith("--") and len(t) > 1:
        body = t[1:]
        if body.startswith("F"):
            if len(body) > 1:
                out += ["file", body[1:]]
                i += 1
            elif i + 1 < len(toks):
                out += ["file", toks[i + 1]]
                i += 2
            else:
                i += 1
            continue
        pos = body.find("m")
        if pos >= 0:
            rest = body[pos + 1:]
            if rest:
                out += ["msg", rest]
                i += 1
            elif i + 1 < len(toks):
                out += ["msg", toks[i + 1]]
                i += 2
            else:
                i += 1
            continue
    i += 1

sys.stdout.write("\0".join(out) + "\0")
PY
}

commit_args_load() {
  COMMIT_ARGS=()
  mapfile -d '' -t COMMIT_ARGS < <(extract_commit_args "$1")
}

# 某类记录的条数。
arg_count() {
  local kind="$1" i n=0
  for ((i = 0; i < ${#COMMIT_ARGS[@]}; i += 2)); do
    [ "${COMMIT_ARGS[i]}" = "$kind" ] && n=$((n + 1))
  done
  printf '%s' "$n"
}

# 某类记录的值，一条一行。
arg_values() {
  local kind="$1" i
  for ((i = 0; i < ${#COMMIT_ARGS[@]}; i += 2)); do
    [ "${COMMIT_ARGS[i]}" = "$kind" ] && printf '%s\n' "${COMMIT_ARGS[i + 1]}"
  done
}

# 类型前缀：feat、fix、docs、style、refactor、chore、test、ci、revert。
# 允许 Conventional Commits 的可选 scope 与 !，大小写不敏感。
TYPE_RE='^(feat|fix|docs|style|refactor|chore|test|ci|revert)(\([^)]*\))?!?:'

has_valid_type() {
  local probe="${1,,}"
  [[ "$probe" =~ $TYPE_RE ]]
}

# 校验一段提交命令里的信息。合格就返回 0，不合格直接拦下（exit 2）。
check_commit_message() {
  local seg="$1" msg count
  commit_args_load "$seg"

  # 解析器不可用时放行，闸门自身出故障不能堵住提交
  [ "${#COMMIT_ARGS[@]}" -gt 0 ] || return 0

  if [ "$(arg_count msg)" = 0 ] && [ "$(arg_count file)" = 0 ] && [ "$(arg_count source)" = 0 ]; then
    report_message_block missing ""
  fi

  count=$(arg_count msg)
  [ "${count:-0}" -gt 1 ] &&
    report_message_block multiline "一次提交给了 ${count} 处 -m / --message"

  # 直接用数组判换行：按行读会把一条多行信息拆成两条，判定就漏了。
  local i
  for ((i = 0; i < ${#COMMIT_ARGS[@]}; i += 2)); do
    [ "${COMMIT_ARGS[i]}" = msg ] || continue
    case "${COMMIT_ARGS[i + 1]}" in
      *$'\n'*) report_message_block multiline "提交信息里带了换行" ;;
    esac
  done

  while IFS= read -r msg; do
    if [ "$msg" = "-" ]; then
      report_message_block multiline "-F - 从标准输入读信息，无法保证单行"
    fi
    [ -f "$msg" ] && [ -r "$msg" ] || continue
    count=$(wc -l <"$msg")
    [ "${count:-0}" -gt 1 ] &&
      report_message_block multiline "-F 指向的文件有 ${count} 行，提交信息必须是单行"
  done < <(arg_values file)

  while IFS= read -r msg; do
    [ -n "$msg" ] || continue
    has_valid_type "$msg" || report_message_block type "$msg"
  done < <(arg_values msg)

  while IFS= read -r path; do
    [ "$path" != "-" ] && [ -f "$path" ] && [ -r "$path" ] || continue
    msg=$(head -n 1 -- "$path")
    [ -n "$msg" ] || continue
    has_valid_type "$msg" || report_message_block type "$msg"
  done < <(arg_values file)
}

# kind 取 type、multiline、missing。提示文本两份闸门共用。
report_message_block() {
  local kind="$1" msg="$2"
  {
    case "$kind" in
      type)
        echo "提交被拦下：提交信息缺少规定的类型前缀"
        echo
        echo "收到的提交信息：$msg"
        ;;
      multiline)
        echo "提交被拦下：提交信息不是单行"
        echo
        echo "问题：$msg"
        ;;
      missing)
        echo "提交被拦下：没有给提交信息"
        ;;
    esac
    echo
    echo "提交信息格式：<type>: <描述>，只有一行。"
    echo "type 必须是：feat、fix、docs、style、refactor、chore、test、ci、revert。"
    echo
    echo "  写成   fix: 门禁记录统计接口补齐无数据的区域"
    echo "  不写   修正门禁记录统计接口"
    echo "  不写   bugfix: 修正门禁记录统计接口"
    echo
    case "$kind" in
      type)
        echo "scope 括号与 ! 可以用：fix(doorRecord): ...、feat(api)!: ..."
        ;;
      multiline)
        echo "多个 -m、引号跨行、-F 文件多行都会拼成多行，提交信息只留一行。"
        ;;
      missing)
        echo "非交互环境里不带 -m 的提交会打开编辑器卡住；沿用上一条信息用 --amend --no-edit。"
        ;;
    esac
    echo
    echo "改好命令后重新执行刚才的提交。"
  } >&2
  exit 2
}
