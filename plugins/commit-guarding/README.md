# commit-guarding

管两件事：

1. **提交信息一行，且带类型前缀**：`feat`、`fix`、`docs`、`style`、`refactor`、`chore`、`test`、`ci`、`revert`。
2. **提交或推送前先拉取最新代码、解决冲突，然后再提交或推送**。

其余 git 与 svn 用法不干预。

SVN 与 git 两种工作副本都管，按目录下有没有 `.svn` 或 `.git` 分流。

## 组件

| 组件 | 类型 | 作用 |
|---|---|---|
| `svn-commit` | 技能 | 提交信息格式；提交前 `svn update`、冲突清零 |
| `git-commit` | 技能 | 提交信息格式；提交与推送前拉取、冲突清零 |
| `svn-commit-guard` | 钩子 | 拦 `svn commit`：信息不合规、落后于服务器或有未解决冲突 |
| `git-commit-guard` | 钩子 | 拦 `git commit`：信息不合规、落后或分叉；拦 `git push`：落后或分叉 |

技能在提交、推送、拉取、冲突时触发；钩子常驻，命令一执行就检查，只拦不改。

## 安装

```bash
claude plugin install commit-guarding@himmeltala-claude-plugins
```

只想在部分项目里启用、其它项目不启用时，加 `-s project` 装到项目级（在项目目录下执行）：

```bash
claude plugin install commit-guarding@himmeltala-claude-plugins -s project
```

市场源地址、缓存机制与更新方式见仓库根目录的 `README.md`。

## 使用

- 说"提交""推送""拉最新""冲突了"：触发对应技能
- `/commit-guarding:svn-commit`、`/commit-guarding:git-commit`：显式调用
- 闸门无需触发，`svn commit`、`git commit`、`git push` 一执行就检查
