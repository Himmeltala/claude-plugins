# local-team

本地团队插件市场。存放本单位自用约定，仓库托管在 GitHub 上，内容只服务本单位的使用场景。市场里八个插件各自独立安装，按项目情况挑选。

| 插件                 | 管什么                                                                                                                                           | 什么时候装                                       |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------ |
| `commit-guarding`  | 版本控制工作流：SVN 与 git 两套提交流程的检查与硬闸门、提交信息格式、命令速查、冲突与撤销踩坑                                                    | 用 SVN 或 git 管的项目都装，按工作副本类型分流   |
| `comment-trimming` | 注释规范：稀疏优先、只讲本段代码、不复述实现、禁装饰、编辑文件时整文件顺手清干净、整目录批量清理的子代理；Java 类头 Javadoc 与前端文件头六字段块单独一个技能 | 所有 Java、Vue 或 JavaScript 项目                |
| `chinese-writing`  | 中文表达与理解：介词、量词、关联词、语序、术语、篇幅、禁符号代字与翻译腔；文档与注释不复述实现细节                                               | 所有项目                                         |
| `code-testing`     | 把代码测通的三段套路：进程外起模拟服务跑通链路、进程内假对端写端到端测试并按覆盖率补测、Java 里写这类测试的构建与 JVM 坑                         | 需要频繁复现链路问题、或要把链路用测试锁住的项目 |
| `bug-tracing`      | 问题排查：先查数据源，数据核实无误再沿调用链读代码，需要时经授权连库取部分数据作证                                                               | 所有项目                                         |
| `code-shaping`     | 编码思维：复用优先、只有第二处要用才抽公共函数、参数过长传对象、胶水代码泛化、模式用得其所、不许过度抽象                                 | 所有项目                                         |
| `output-guard`     | AI 输出规范：排查与故障结论、代码改动说明、进度与结果汇报三类结构，按内容伸缩；输出侧省 token，结论先行、不复述、只给相关片段                 | 所有项目                                         |
| `input-guard`      | AI 输入检查：敏感信息与脱敏、输入要素补全、从源头省 token；只管输入侧，不压缩回复                                                                | 所有项目                                         |

## 安装

每个插件目录同时是 Claude Code 插件和 npm 包：`.claude-plugin/`、`hooks/`、`agents/` 给 Claude，`package.json`、`cordis.patch.yml`、`lib/` 给 DSH，`skills/` 两边共用同一份文件。`package.json` 与 `.claude-plugin/plugin.json` 的 version 必须一起改，前者决定 npm 版本，后者决定 Claude 的缓存目录。

### Claude Code

市场源是 GitHub 上的 `Himmeltala/local-team` 仓库，本机工作副本在 `~/pros/self/local-team`：

```bash
claude plugin marketplace add Himmeltala/local-team
claude plugin install commit-guarding@local-team
claude plugin install comment-trimming@local-team
claude plugin install chinese-writing@local-team
claude plugin install code-testing@local-team
claude plugin install bug-tracing@local-team
claude plugin install code-shaping@local-team
claude plugin install output-guard@local-team
claude plugin install input-guard@local-team
```

只想在部分项目里启用时，在该项目目录下加 `-s project` 装到项目级：

```bash
claude plugin install commit-guarding@local-team -s project
```

插件内容是复制到 `~/.claude/plugins/cache/local-team/<插件名>/<版本>/` 的，改源目录不会自动生效。更新内容时，先运行 `claude plugin marketplace update local-team`，再运行 `claude plugin update <插件名>@local-team`，之后重启会话（钩子在会话启动时加载）。

旧名字装过的，先卸掉再装新的——缓存目录按插件名分，改名的插件不会被自动接管：

```bash
claude plugin uninstall control-workflow@local-team
claude plugin uninstall comment-style@local-team
claude plugin uninstall mock-testing@local-team
claude plugin install commit-guarding@local-team
claude plugin install comment-trimming@local-team
claude plugin install code-testing@local-team
```

更早的两个旧名（`svn-team-conventions`、`svn-workflow`）同样先卸后装。

`mock-testing` 改名为 `code-testing` 后，技能拆成四个，原来的 `mock-testing:mock-testing` 变成 `code-testing:mock-testing`。

### DSH

DSH 自带插件安装，不用先发 npm，也不走上架：仓库已公开，直接从 GitHub 子目录装。

```bash
dsh plugin --profile web add github:Himmeltala/local-team#path:/plugins/commit-guarding
```

改源码时用本地路径，改动立即生效：

```bash
dsh plugin --profile web add ./plugins/commit-guarding
```

以后发布到 npm 后，命令换成包名 `dsh-local-team-commit-guarding`。

DSH 侧由 `lib/index.js` 把包内 `skills/` 注册成技能，装完即用，不需要往 `~/.dsh/skills` 拷贝。`commit-guarding` 的提交闸门由 `lib/guard.js` 在 bash 调用前复跑同一批脚本；Claude 的 `hooks.json` 与 `agents/` 不参与 DSH。

以前用软链把技能挂进 `~/.dsh/skills` 的，切到包安装后先删掉对应软链，否则同名技能按 rank 仍然命中软链那份。

dshmarket 的列表只读 awesome-dsh-plugin 的目录，收录要向上游提 PR；本仓库不走那条路，市场里搜不到，不影响安装。

改动后跑 `node scripts/check-plugins.mjs`，它校验版本一致、包名、技能数量与提交闸门。

## 使用

技能多数会自动触发，不必记命令。各插件的显式调用路径、触发词与适用范围，写在各插件目录下的 README 里。

篇幅与符号这类全局规则的值只有一份，在 `chinese-writing` 插件的篇幅标准里，其余插件只指认不另写。
