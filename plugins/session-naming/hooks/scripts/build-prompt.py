# 从 transcript 里摘出首条提问和最近若干轮对话，拼成给模型的概括指令。
#
# 只留普通文本：工具调用、工具结果、系统提示、侧链（子代理）对话全部扔掉，它们既长又
# 不说明主题。每条截断到 400 字，总量封顶 6000 字，标题用不着全文。
import json
import re
import sys

from collections import deque

MAX_PER_MESSAGE = 400
MAX_TOTAL = 6000
TAIL_MESSAGES = 12

SYSTEM_TOKEN = re.compile(
    r"<system-reminder>.*?</system-reminder>"
    r"|<local-command-[^>]*>.*?</local-command-[^>]*>"
    r"|<command-name>.*?</command-name>"
    r"|<command-message>.*?</command-message>",
    re.S,
)


def text_of(content):
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    parts = []
    for block in content:
        if isinstance(block, dict) and block.get("type") == "text":
            text = block.get("text")
            if isinstance(text, str):
                parts.append(text)
    return "\n".join(parts)


def clean(text):
    text = SYSTEM_TOKEN.sub(" ", text)
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) > MAX_PER_MESSAGE:
        text = text[:MAX_PER_MESSAGE] + "…"
    return text


def main():
    path = sys.argv[1]
    first_user = ""
    tail = deque(maxlen=TAIL_MESSAGES)

    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            for line in handle:
                if '"role"' not in line:
                    continue
                try:
                    entry = json.loads(line)
                except Exception:
                    continue
                if entry.get("type") not in ("user", "assistant") or entry.get("isSidechain"):
                    continue
                message = entry.get("message") or {}
                role = message.get("role")
                if role not in ("user", "assistant"):
                    continue
                text = clean(text_of(message.get("content")))
                if not text:
                    continue
                if role == "user" and not first_user:
                    first_user = text
                tail.append((role, text))
    except OSError:
        return 1

    if not first_user and not tail:
        return 1

    lines = ["下面是一次开发会话的片段。请用不超过十二个字的短语概括这段会话的主题。",
             "只输出标题本身，不加引号、不加标点、不加解释，不要写“标题：”这样的前缀。",
             "会话用什么语言就用什么语言。", ""]
    if first_user:
        lines.append("首条提问：" + first_user)
        lines.append("")
    lines.append("最近对话：")
    for role, text in tail:
        lines.append(("用户：" if role == "user" else "助手：") + text)

    prompt = "\n".join(lines)
    sys.stdout.write(prompt[:MAX_TOTAL])
    return 0


if __name__ == "__main__":
    sys.exit(main())
