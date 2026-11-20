# chinese-writing

中文表达与理解规范插件：约束助手怎么写中文，以及怎么读中文需求。

## 组件

| 组件 | 类型 | 作用 |
|---|---|---|
| `chinese-writing` | 技能 | 落盘产出十条、篇幅标准、读需求的歧义确认 |

技能内另有三份参考：`symbols-and-grammar.md`（符号与语法）、`translationese.md`（翻译腔）、`reading-chinese.md`（读需求）。

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

技能会在写注释、文档、提交信息时自动触发，也可以显式调用：

- 说"中文不通""缺介词""符号代字""翻译腔" —— 触发规则
- `/chinese-writing:chinese-writing` —— 显式走一遍规则
