#!/usr/bin/env bash
# 钩子与 worker 共用的部分：路径、钩子输入解析、状态文件读写、从 transcript 取已有标题。
#
# 状态按会话分开存，一个会话一个文件，内容是 key=value 一行一项。不存 JSON，
# 是因为这里读写都在 bash 里，解析 JSON 还要再叫一次 python3，而字段只有四五个。
#
# 任何异常一律放行：钩子只做锦上添花，自身出故障时绝不能堵住用户的提问。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${CLAUDE_PLUGIN_DATA:-${XDG_CACHE_HOME:-$HOME/.cache}/claude-session-naming}"
INTERVAL="${SESSION_NAMING_INTERVAL:-4}"

case "$INTERVAL" in
  '' | *[!0-9]*) INTERVAL=4 ;;
esac
[ "$INTERVAL" -ge 1 ] || INTERVAL=1

# 输出钩子输入里的七个字段，用 NUL 分隔：事件名、会话 ID、transcript 路径、提问正文、
# 提问来源、当前标题、工作目录。bash 变量存不了 NUL，调用方用 mapfile 接。
parse_input() {
  local raw="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(1)
keys = ("hook_event_name", "session_id", "transcript_path", "prompt", "source", "session_title", "cwd")
# 末尾补一个 NUL：最后一段常为空（比如没有 session_title），不补的话 mapfile 读不到它
sys.stdout.write("\0".join("" if d.get(k) is None else str(d.get(k)) for k in keys) + "\0")
' <<<"$raw" 2>/dev/null
  elif command -v jq >/dev/null 2>&1; then
    jq -j '[.hook_event_name // "", .session_id // "", .transcript_path // "",
            .prompt // "", .source // "", .session_title // "", .cwd // ""]
           | join("\u0000") + "\u0000"' \
      <<<"$raw" 2>/dev/null
  else
    return 1
  fi
}

# 标题写回会话。只有 hookSpecificOutput.sessionTitle 这一条路能让 Claude Code 改标题，
# 且只认 SessionStart 与 UserPromptSubmit 两个事件——本插件用的是后者。
emit_title() {
  local title="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json, sys
print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit",
                                         "sessionTitle": sys.argv[1]}}, ensure_ascii=False))
' "$title"
  elif command -v jq >/dev/null 2>&1; then
    jq -nc --arg t "$title" \
      '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $t}}'
  fi
}

# 标题前缀用的项目名：取工作目录的最后一段。目录名就是项目名，不向上找 git 仓库，
# 也不读项目文件。根目录这种取不到名字的情况输出空串，调用方不加前缀。
project_name() { # 目录路径
  local path="${1:-}"
  path="${path//$'\n'/}"
  path="${path//$'\r'/}"
  path="${path%/}"
  path="${path##*/}"
  printf '%s' "$path"
}

# 会话标题统一写成「项目名:标题」。手动改名判据比对的是完整标题，所以前缀必须
# 和 pending、applied 一起存，回填时原样发出，不能在发出那一刻才拼。
compose_title() { # 项目名 标题
  if [ -n "${1:-}" ]; then
    printf '%s:%s' "$1" "$2"
  else
    printf '%s' "$2"
  fi
}

state_get() { # 文件 键
  [ -f "$1" ] || return 0
  sed -n "s/^$2=//p" "$1" 2>/dev/null | tail -n 1
}

# 先写临时文件再 mv，worker 与钩子同时动一个文件时不会读到写了一半的内容。
state_set() { # 文件 键 值
  local file="$1" key="$2" value="$3" tmp
  mkdir -p "$(dirname "$file")" 2>/dev/null || return 1
  tmp=$(mktemp "${file}.XXXXXX" 2>/dev/null) || return 1
  if [ -f "$file" ]; then
    grep -v "^${key}=" "$file" >"$tmp" 2>/dev/null || : >"$tmp"
  fi
  printf '%s=%s\n' "$key" "$value" >>"$tmp"
  mv -f "$tmp" "$file" 2>/dev/null || rm -f "$tmp"
}

# transcript 里最后一条 custom-title。钩子设置的标题，Claude Code 同样写成
# custom-title，与用户 /rename 的结果在文件里没有区别，只能靠与自己上次回填的值比对
# 来认出「用户手动改过」。只读末尾两千行：标题每条消息都会重新落一次，总在尾部。
#
# 建会话时就带标题的情况另算：Claude Code 在 /clear 或从已有会话续开时，把当前会话的
# 标题当成新会话的初始元数据写在文件最前面，新会话一出生就顶着上一个会话的名字。
# 这种标题不是用户改的，用 inherited_title 单独认出来。
last_custom_title() { # transcript
  [ -f "$1" ] || return 0
  if command -v python3 >/dev/null 2>&1; then
    tail -n 2000 -- "$1" 2>/dev/null | python3 -c '
import json, sys
last = ""
for line in sys.stdin:
    if "custom-title" not in line:
        continue
    try:
        d = json.loads(line)
    except Exception:
        continue
    if d.get("type") == "custom-title" and isinstance(d.get("customTitle"), str):
        last = d["customTitle"]
sys.stdout.write(last)
' 2>/dev/null
  elif command -v jq >/dev/null 2>&1; then
    tail -n 2000 -- "$1" 2>/dev/null |
      jq -R -r 'fromjson? | select(.type == "custom-title") | .customTitle' 2>/dev/null |
      tail -n 1
  fi
}

# transcript 的第一条记录就是 custom-title，说明标题是建会话时继承来的：
# 这种继承标题写在文件最前面，而用户 /rename 只会往文件尾部追加，不会落在第一行。
# 输出该标题；首条记录不是标题时什么都不输出。
inherited_title() { # transcript
  [ -f "$1" ] || return 0
  if command -v python3 >/dev/null 2>&1; then
    head -n 5 -- "$1" 2>/dev/null | python3 -c '
import json, sys
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        entry = json.loads(line)
    except Exception:
        sys.exit(1)
    if entry.get("type") == "custom-title" and isinstance(entry.get("customTitle"), str):
        sys.stdout.write(entry["customTitle"])
    sys.exit(0)
' 2>/dev/null
  elif command -v jq >/dev/null 2>&1; then
    head -n 5 -- "$1" 2>/dev/null |
      jq -R -r 'fromjson? | select(.type == "custom-title") | .customTitle' 2>/dev/null |
      head -n 1
  fi
}
