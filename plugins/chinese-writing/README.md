# chinese-writing

插件只约束一件事：AI 写中文时，用词、标点符号、语序符合中文。篇幅、文档结构、任务理解都不归它管。

## 组件

| 组件 | 类型 | 作用 |
|---|---|---|
| `chinese-writing` | 技能 | 中文用词、标点符号、语序规则 |

参考文件两份：`symbols-and-grammar.md`（符号、介词、量词、语序、混排）、`translationese.md`（翻译腔对照）。

## 安装

```bash
claude plugin install chinese-writing@himmeltala-claude-plugins
```

只想在部分项目里启用时，在该项目目录下加 `-s project` 装到项目级：

```bash
claude plugin install chinese-writing@himmeltala-claude-plugins -s project
```

市场源地址、缓存机制与更新方式见仓库根目录的 `README.md`。

## 使用

技能会在写中文时自动触发，也可以显式调用：

- 说"中文不通""缺介词""符号代字""翻译腔""语序不对" —— 触发规则
- `/chinese-writing:chinese-writing` —— 显式走一遍规则
