# 把模型返回的那段文字收拾成能直接当标题用的一行。
#
# 模型再怎么说“只输出标题”，也可能带回引号、加粗、句号、或者前面挂一句“标题：”。
# 这些东西进标题栏很难看，且标题里带换行或引号会破坏状态文件的 key=value 结构，
# 所以逐项去掉，最后按字符数截断——按字符不按字节，免得把汉字切一半。
import re
import sys

MAX_CHARS = 24


def main():
    text = sys.stdin.read()
    for line in text.splitlines():
        line = line.strip()
        if line:
            text = line
            break
    text = re.sub(r"^(?:#+\s*|\*\*)", "", text)
    text = re.sub(r"^(?:会话)?标题[:：]\s*", "", text)
    # 引号、加粗、句号可能一层套一层（**「标题」**。），剥到不再变化为止
    previous = None
    while text != previous:
        previous = text
        text = text.strip("\"'“”‘’「」『』`*# 　")
        text = re.sub(r"[。．.！!？?，,；;：:]+$", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) > MAX_CHARS:
        text = text[:MAX_CHARS]
    sys.stdout.write(text)
    return 0 if text else 1


if __name__ == "__main__":
    sys.exit(main())
