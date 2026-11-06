---
name: git-commit
description: 当用户要求提交到 git 仓库、推送、写提交说明、查看改动、拉取远端、解决冲突、回滚撤销时使用。触发词包括"提交"、"提交代码"、"git commit"、"commit 一下"、"推送"、"push"、"改了什么"、"git status"、"git diff"、"git log"、"拉最新代码"、"git pull"、"冲突了"、"回滚"、"撤销修改"、"看历史"。也用于工作副本是 git 的场合。
argument-hint: "[要提交的路径] [本次改动的一句话说明]"
allowed-tools: [Bash, Read, Grep, Glob]
---

# git 提交工作流

用户调用时带了参数，参数在用户消息里，也填进 `$ARGUMENTS`。

- 参数是路径：只处理该路径范围，其余文件不纳入本次提交。
- 参数是改动说明：当作提交信息的草稿，整理成一行。
- 无参数：走完整流程，从 `git status` 开始；写好的提交信息在提交前给用户过目。用户不在场（子代理、无人值守）时，按仓库历史里的既有写法自己定一行，提交后在报告里原样列出并说明是自行定的。

## 铁律：先认清这是哪个版本控制系统

- 有 `.git` 用 git 这套命令；有 `.svn` 换 `svn-commit` 技能。两套不混用。
- 动手前先 `git rev-parse --is-inside-work-tree` 与 `git status -sb`，不要凭记忆写路径。
- 自用项目的仓库直接在 `main` 上提交，**不建分支、不建 PR、不写 `Co-Authored-By` 尾注**。
- **推送由用户明确要求才做**；用户说"推送"时，先确认远端没有别人的新提交再推。

## 提交流程

**闸门：提交前先拉最新。** 本地落后于远端、或与远端分叉时，`git commit` 会被本插件的 PreToolUse 钩子拦下（退出码 2）。这是插件级钩子，不是仓库里的 `.git/hooks`，`ls .git/hooks` 里看不到，别拿它判断闸门在不在；没装本插件的环境没有这道兜底。钩子只拦不改，`fetch` 与 `pull --rebase` 仍由你手工做完。

1. **确认位置**——`git rev-parse --is-inside-work-tree`、`git status -sb`，看分支与上下游差多少。
2. **对齐远端**——`git fetch`，再看 `git status -sb`。落后或分叉时：工作区干净就 `git pull --rebase`；**有未提交改动**先 `git stash push -u`，拉完 `git stash pop`（直接变基会被拒绝：`不能变基式拉取：您的索引中包含未提交的变更`）。不要先提交再拉——闸门拦的正是落后状态下的提交。冲突未清零不往下走，处理见「失败与冲突」。`fetch` 因权限或网络失败时，先报告并说明远端未核对；用户要求继续再提交。
3. **看改动并暂存**——`git status --short` 取清单，`git diff`、`git diff --cached` 逐行读（只看清单用 `git diff --stat`）。新文件**逐个 `git add <路径>`，不要 `git add -A` 或 `git add .`**；只 add 说得出来历的文件，来历不明的未跟踪文件不动也不删，在报告里问用户。
4. **自检**——查调试残留（`console.log`、`debugger`、注释掉的旧代码）、误改的配置文件、混入的 `node_modules/` 或 `dist/` 或 `out/`。
5. **写信息并提交**——单行，见下节。`git commit -m "<信息>"`，需要限定范围时显式列路径；提交后用 `git log --oneline -1` 与 `git status -sb` 核对落在预期分支上。
6. **推送**——用户明确要求时才 `git push`；推完 `git status -sb` 应与远端一致。

## 提交信息：只有一行

```
<type>: <中文描述>
```

只有一行，前缀后面不加范围括号，冒号用半角，描述用中文。一行说不清说明这次提交装的事太多，**拆成多次提交，每次一行**。

整行长度、前缀含义与更多正反例见 `../../references/commit-message-format.md`——git 与 SVN 共用同一套格式，只有提交命令不同。

## 闸门拦哪四类

| 拦下的情况 | 提示里给的出路 |
|---|---|
| 前缀带范围括号（`feat(api):` 等） | 把模块名写进中文描述 |
| 信息不是单行（两处 `-m`、引号跨行、`-F` 文件多行、`-F -`） | 拆成多次提交，每次一行 |
| 没给信息（裸 `git commit`、`git commit --amend`） | 用 `-m`；沿用上一条用 `--amend --no-edit` |
| 处于 detached HEAD，或本地落后或分叉于远端 | 落后先 `git pull --rebase`；游离 HEAD 先 `git switch -c <新分支名>` |

变基、摘樱桃、合并过程中的游离 HEAD 不算异常；远端不可达时跳过落后判定。

## 命令速查

上面各步骤已经出现的命令不再重复，下表只列流程里没提到的：

| 目的 | 命令 |
|---|---|
| 近期历史 | `git log --oneline -10` |
| 某行是谁改的 | `git blame <file>` |
| 标记删除 | `git rm <path>` |
| 撤销工作区改动或暂存 | `git restore <path>`（不可恢复，先确认）、`git restore --staged <path>` |
| 已推送的错误提交 | `git revert <sha>`，再推一次 |

## 失败与冲突

**变基冲突。** `git status` 里标 `both modified` 的就是冲突文件。

1. 打开文件手工解决，把 `<<<<<<<`、`=======`、`>>>>>>>` 三种标记清干净。
2. `git add <冲突文件>`，然后 `git rebase --continue`。
3. `git status` 确认没有冲突文件，再继续提交。

**先判冲突能不能自己解：**

| 冲突形态 | 处置 |
|---|---|
| 两边改的是不同位置、不同逻辑，合起来本来就该都在 | 自己合并，两边内容都保留 |
| 同一行两边改成不同取值，或同一段逻辑被改出两种互斥的写法 | 停下问用户留哪一边 |

第二种的「解决」本身就是取舍，等于替用户在两个人的改动之间挑一个，不要自己拍。判断办法：看冲突块里 `<<<<<<<` 与 `>>>>>>>` 两侧的内容能不能共存，不能共存就是取舍题。停下来时把两侧内容、各自的提交信息、涉及的文件列清楚。放弃变基用 `git rebase --abort`——**会丢掉变基过程中已解决的改动**，执行前先跟用户确认。

**分叉与 detached HEAD。** 分叉时不要直接 `git push`（会被拒），也不要默认 force push，先 `git pull --rebase`，冲突按上面那张表判。游离 HEAD 上提交的改动不属于任何分支，切走就找不回来，先 `git switch -c <新分支名>`。

**撤销改动。**

| 情况 | 做法 |
|---|---|
| 未提交的工作区改动 | `git restore <path>`（不可恢复） |
| 已提交、**未推送** | `git reset --soft HEAD^` 退回暂存，或 `git commit --amend` 改信息与内容 |
| 已提交、**已推送** | `git revert <sha>` 生成一条反向提交再推。已推送的历史不改写 |
| 远端有别人的提交 | 绝不 force push，用 revert |

**force push。** 只在独占、确认远端没有别人提交的仓库里，且用户明确要求时才做，用 `git push --force-with-lease` 而不是 `--force`：前者在远端有新提交时会拒绝。

**两个环境问题。** 中断的 git 命令会留下 `.git/index.lock`，报 `Unable to create ... index.lock`，确认没有 git 进程在跑之后删掉它；提交信息写入乱码时，用 `git config --local i18n.commitEncoding utf-8` 与 `locale` 查编码。

## 已知坑

- **裸 git commit。** 不带 `-m` 会打开编辑器，非交互环境下命令一直卡住。这条有钩子兜底。
- **`git add -A` 带进产物。** `node_modules/`、`dist/`、`out/` 会被一起提交，这些目录该写进 `.gitignore`。
- **改动已推送还 `--amend`。** 改写了已发布的历史，别人再拉会分叉；已推送的用 `git revert`。
