# commit-guarding

版本控制工作流插件：管提交前的检查与拦截。注释规范在 `comment-trimming` 插件，中文规范在 `chinese-writing` 插件，三者互不依赖，装哪个用哪个。

SVN 与 git 两种工作副本都管，按目录下有没有 `.svn` 或 `.git` 分流：同一个会话里既有 SVN 项目又有 git 项目也能用，各自走各自那套。工作副本不在版本控制之下的不需要它。

## 组件

| 组件 | 类型 | 作用 |
|---|---|---|
| `svn-commit` | 技能 | 提交前检查流程、提交信息格式、SVN 命令速查、冲突与编码踩坑处理 |
| `git-commit` | 技能 | 提交前拉最新、提交信息格式、git 命令速查、变基冲突与撤销处理。提交信息格式与 `svn-commit` 共用一份细则 |
| svn-commit-guard | 钩子 | PreToolUse 拦 `svn commit`：工作副本落后于服务器、有未解决冲突、提交信息前缀带范围括号 |
| git-commit-guard | 钩子 | PreToolUse 拦 `git commit`：前缀带范围括号、信息不是单行、没给信息、处于 detached HEAD、落后或分叉于远端 |

提交细则在技能触发时加载；PreToolUse 闸门常驻，提交命令一执行就检查。

## 安装

```bash
claude plugin install commit-guarding@local-team
```

只想在部分项目里启用、其它项目不启用时，加 `-s project` 装到项目级（在项目目录下执行）：

```bash
claude plugin install commit-guarding@local-team -s project
```


市场源地址、缓存机制与更新方式见仓库根目录的 `README.md`。

## 使用

技能多数会自动触发，也可以显式调用：

- `/commit-guarding:svn-commit` —— 走一遍 SVN 提交流程并生成提交信息
- `/commit-guarding:git-commit` —— 走一遍 git 提交流程并生成提交信息

触发词包括"提交"、"提交代码"、"git commit"、"svn commit"、"改了什么"、"git status"、"svn status"、"推送"、"拉最新代码"、"冲突了"、"回滚"、"撤销修改"、"看历史"。提交闸门的两份钩子无需触发，提交命令一执行就生效。
