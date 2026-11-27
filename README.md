# himmeltala-claude-plugins

本地团队插件市场。存放本单位自用约定，仓库托管在 GitHub 上，内容只服务本单位的使用场景。市场里五个插件各自独立安装，按项目情况挑选。

| 插件                 | 管什么                                                                                                                                           | 什么时候装                                       |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------ |
| `commit-guarding`  | 版本控制约束：提交信息单行并带 feat、fix、docs 等类型前缀；提交或推送前先拉最新、解决冲突；其余用法不干预                                      | 用 SVN 或 git 管的项目都装，按工作副本类型分流   |
| `comment-trimming` | 注释规范：默认不写、写则一行、只讲本段代码、禁装饰；编辑文件时整文件顺手清干净，整目录批量清理交给 comment-trimmer；类头 Javadoc 与前端文件头单独一个技能 | 所有 Java、Vue 或 JavaScript 项目                |
| `chinese-writing`  | 中文写作：用词、标点符号、语序符合中文；禁符号代字与翻译腔，中英混排加空格                                                                       | 所有项目                                         |
| `software-architecture` | 代码架构：边界、单向数据流、状态归属、组合与抽象时机、质量约束前置；前端部分框架无关                           | 前端项目，或需要长期演进的代码库                 |
| `session-naming`   | 会话标题：内置 AI 标题只在首轮生成一次，本插件在后台按对话内容重新概括并经钩子回填；用户 `/rename` 过的会话自动停手                              | 会话开得长、要按主题找历史会话                   |

## 安装

每个插件目录是 Claude Code 插件，按需包含 `.claude-plugin/`、`hooks/`、`agents/`、`skills/` 等子目录。版本写在 `.claude-plugin/plugin.json` 的 version 里，决定 Claude 的缓存目录。DSH 版本的 `commit-guarding`、`comment-trimming`、`chinese-writing` 在 `Himmeltala/dsh-plugins` 仓库，本仓库只适配 Claude Code。

### Claude Code

市场源是 GitHub 上的 `Himmeltala/claude-plugins` 仓库（市场名 `himmeltala-claude-plugins`），本机工作副本在 `~/pros/self/claude-plugins`：

```bash
claude plugin marketplace add Himmeltala/claude-plugins
claude plugin install commit-guarding@himmeltala-claude-plugins
claude plugin install comment-trimming@himmeltala-claude-plugins
claude plugin install chinese-writing@himmeltala-claude-plugins
claude plugin install session-naming@himmeltala-claude-plugins
claude plugin install software-architecture@himmeltala-claude-plugins
```

只想在部分项目里启用时，在该项目目录下加 `-s project` 装到项目级：

```bash
claude plugin install commit-guarding@himmeltala-claude-plugins -s project
```

插件内容是复制到 `~/.claude/plugins/cache/himmeltala-claude-plugins/<插件名>/<版本>/` 的，改源目录不会自动生效。更新内容时，先运行 `claude plugin marketplace update himmeltala-claude-plugins`，再运行 `claude plugin update <插件名>@himmeltala-claude-plugins`，之后重启会话（钩子在会话启动时加载）。

旧名字装过的，先卸掉再装新的——缓存目录按插件名分，改名的插件不会被自动接管：

```bash
claude plugin uninstall control-workflow@himmeltala-claude-plugins
claude plugin uninstall comment-style@himmeltala-claude-plugins
claude plugin uninstall mock-testing@himmeltala-claude-plugins
claude plugin install commit-guarding@himmeltala-claude-plugins
claude plugin install comment-trimming@himmeltala-claude-plugins
```

更早的两个旧名（`svn-team-conventions`、`svn-workflow`）同样先卸后装。

改动后跑 `node scripts/check-plugins.mjs`，它校验插件清单、技能数量与提交闸门脚本。

## 使用

技能多数会自动触发，不必记命令。各插件的显式调用路径、触发词与适用范围，写在各插件目录下的 README 里。

各插件的规则各自维护，互不依赖：中文写法在 `chinese-writing`，注释在 `comment-trimming`，提交信息与提交前拉取在 `commit-guarding`，代码架构在 `software-architecture`。
