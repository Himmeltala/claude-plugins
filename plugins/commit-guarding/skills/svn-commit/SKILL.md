---
name: svn-commit
description: 当用户要求提交代码到 SVN、写提交说明、查看工作副本改动、解决更新冲突、回滚撤销改动时使用。触发词包括"提交"、"提交代码"、"svn commit"、"commit 一下"、"改了什么"、"svn status"、"svn diff"、"svn log"、"拉最新代码"、"更新一下代码"、"冲突了"、"回滚"、"撤销修改"、"看历史"。也用于用户误用 git（git diff/log/commit、分支、PR）需要纠正的场合。
argument-hint: "[要提交的路径] [本次改动的一句话说明]"
allowed-tools: [Bash, Read, Grep, Glob]
---

# SVN 提交工作流

用户调用时带了参数，参数在用户消息里，也填进 `$ARGUMENTS`。

- 参数是路径：只处理该路径范围，其余文件不纳入本次提交。
- 参数是改动说明：当作提交信息的草稿，整理成一行。
- 无参数：走完整流程，从 `svn status` 开始。提交前把提交信息给用户过目；用户不在场（子代理、无人值守）时，按仓库历史里的既有写法自己定一行，提交后在报告里原样列出并说明是自行定的。

## 铁律：这是 SVN，不是 git

- 绝不用 `git diff` / `git log` / `git status` / `git commit` / `git blame`；不建分支、不建 PR、不写 `Co-Authored-By` 尾注。
- **工作副本是 git 仓库（目录下有 `.git`）时换 `git-commit` 技能。** 两者提交信息格式相同，命令与前置检查不同。
- **先 `svn info` 定位工作副本。** 工作区根目录本身通常不是工作副本，只有含 `.svn` 的项目子目录才是；版本库可达性用 `svn info <URL>` 测，报错即不通。路径按 `svn info` 的输出为准，不要凭记忆写。

## 提交流程

**闸门：先 `svn update`，冲突清零。** 这两件事没做完，不要执行 `svn commit`。插件的 PreToolUse 钩子（`hooks/scripts/svn-commit-guard.sh`）提交前会跑一次 `svn status -u`：落后于服务器、或 `svn status` 里还有标 `C` 的文件，直接以退出码 2 拦下并说明原因；`-m` / `--message` / `-F` 文件首行里出现 `feat(xxx):` 这种带范围括号的前缀，同样拦下。钩子只拦不改，工作副本由你按下面步骤处理。

1. **确认位置**——`svn info` 看 URL 与版本，确认目录属于哪个工作副本。
2. **先更新**——`svn update`。不能省，也不能等提交报错了再补。更新因权限、网络或锁失败时，先报告原因，不要绕过。
3. **冲突清零**——`svn status` 里不允许还剩 `C`，有冲突就按文末「失败与冲突」处理完再往下走。
4. **看改动**——`svn status` 取文件清单，`svn diff` 逐行读；只想看清单用 `svn diff --summarize`。
5. **处理未纳管文件**——新增文件必须 `svn add`，删除的文件用 `svn delete`。漏 add 会让提交缺文件，且不留痕迹。
6. **自检**——查调试残留（`System.out`、`console.log`、注释掉的旧代码）、误改的配置文件、混入的 `target/` 或 `node_modules/`。
7. **写提交信息**——单行，见下。
8. **提交**——`svn commit -m "<信息>" [路径...]`。显式列出本次相关文件，避免在工作副本根裸跑 `svn commit` 把无关改动一起送上。
9. **核对**——`svn status` 确认目标文件已不在待提交列表，`svn log -l 1` 看提交信息与版本号落在预期位置。

## 提交信息：只有一行

```
<type>: <中文描述>
```

只有一行，前缀后面不加范围括号，冒号用半角，描述用中文。一行说不清就拆成多次提交。整行长度、前缀含义与更多正反例见 `../../references/commit-message-format.md`。

## 命令速查

流程里已出现的命令不再重复，下表只列其余的：

| 目的 | 命令 |
|---|---|
| 是否落后服务器、有无冲突 | `svn status -u`（提交闸门跑的就是它） |
| 近期历史 | `svn log -l 10` |
| 某行是谁改的 | `svn blame <file>` |
| 撤销本地改动 | `svn revert <path>`（不可恢复，先确认） |

## 失败与冲突

**更新产生冲突。** `svn status` 会显示 `C` 状态，工作目录里多出 `xxx.mine`、`xxx.r<版本号>` 几个文件。冲突没解决前钩子会一直拦着 `svn commit`，这是预期行为，不要去绕。

1. 打开目标文件手工解决，把 `<<<<<<<`、`=======`、`>>>>>>>` 三种标记清干净。
2. `svn resolve --accept=working <path>` 告诉 svn 已解决。
3. `svn status` 确认不再有 `C`，再 `svn commit`。

`--accept=working` **不会自动清掉冲突标记**——标记留在文件里，可能还能编译，但结果是错的，resolve 之后必须打开文件确认标记已删干净。

放弃自己的改动：`svn revert <path>` 然后 `svn update`。`revert` 不可恢复，执行前先确认改动是否已备份或已提交。

整体取一边（只在读过 diff 之后用）：`svn resolve --accept=theirs-full <path>` 整体用服务器版本，丢弃本地改动；`svn resolve --accept=mine-full <path>` 整体用本地版本，丢弃服务器改动。

**常见报错：**

| 报错 | 原因与处理 |
|---|---|
| `E155004` working copy locked | 中断的 update 留下锁，`svn cleanup` 后重试 |
| `E160028` out-of-date | 提交前没 update，`svn update` 后重新提交 |
| `E155010` 已存在同名未纳管文件 | 先确认是否要 `svn add`，不要直接覆盖 |

提交是整体事务：中途失败则全部回滚，不会一半入库，修好问题重新提交即可。

## 已知坑

- **全角冒号**——`feat： xxx` 会被工具链与检索当成脏数据。
- **编码损坏**——历史上出现过提交信息入库后变成 `æ–°å¢ž...` 这类乱码。修复需 `svn propset --revprop -r <版本号> svn:log "<正确文本>"`，且服务端须开 `pre-revprop-change` 钩子；提交前用 `locale` 确认终端为 UTF-8。
- **裸提交**——在工作副本根裸跑 `svn commit` 会带上全部改动。

## 附加资源

- `../../references/commit-message-format.md`——前缀含义、单行写法、更多正反例（与 `git-commit` 共用）。

改代码时同时遵守注释规范，见 `comment-trimming` 插件。
