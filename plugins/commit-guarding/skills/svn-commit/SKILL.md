---
name: svn-commit
description: 当要提交 svn 代码、更新工作副本、解决冲突时使用。触发词：提交、提交代码、svn commit、更新、svn update、拉最新、冲突。
argument-hint: "[要提交的路径]"
allowed-tools: [Bash, Read, Grep, Glob]
---

# SVN 提交

目录下有 `.svn` 用本技能；有 `.git` 用 `git-commit`。

## 提交信息：一行，带类型

`<type>: <描述>`，只有一行。type 必须是：`feat`、`fix`、`docs`、`style`、`refactor`、`chore`、`test`、`ci`、`revert`。

Conventional Commits 的 scope 与 `!` 可以用：`fix(doorRecord): ...`、`feat(api)!: ...`。多个 `-m`、引号跨行、`-F` 文件多行都会被钩子拦下。

## 规则：先更新，冲突清零，再提交

1. **提交前** `svn update`。
2. **冲突清零**：`svn status` 里不能剩 `C`。有冲突就打开文件清干净 `<<<<<<<`、`=======`、`>>>>>>>`，再 `svn resolve --accept=working <文件>`。
   - `--accept=working` 不会自动清掉冲突标记，resolve 之后必须打开文件确认标记已删干净。
3. **冲突清零后** `svn commit`。

工作副本落后或还有冲突时，插件的 PreToolUse 钩子会拦下 `svn commit` 并提示。钩子不改工作副本，更新与解冲突由你手工完成。

## 冲突取舍

同一处两边改成不同内容、无法共存时，不替用户选：把两侧内容、涉及文件与提交信息列清楚，让用户决定。`svn revert` 不可恢复，执行前先确认。

提交信息怎么写、回滚、查看历史，按用户当次要求处理，本插件不另定规则。
