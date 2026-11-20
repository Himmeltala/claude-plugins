---
name: git-commit
description: 当要提交或推送 git 代码、拉取远端、解决冲突时使用。触发词：提交、提交代码、git commit、推送、push、拉最新、git pull、冲突。
argument-hint: "[要提交的路径]"
allowed-tools: [Bash, Read, Grep, Glob]
---

# git 提交与推送

目录下有 `.git` 用本技能；有 `.svn` 用 `svn-commit`。

## 提交信息：一行，带类型

`<type>: <描述>`，只有一行。type 必须是：`feat`、`fix`、`docs`、`style`、`refactor`、`chore`、`test`、`ci`、`revert`。

Conventional Commits 的 scope 与 `!` 可以用：`fix(doorRecord): ...`、`feat(api)!: ...`。多个 `-m`、引号跨行、`-F` 文件多行都会被钩子拦下。

## 规则：先拉最新，冲突清零，再提交或推送

1. **提交前对齐远端**：`git fetch`，看 `git status -sb`。
   - 落后或分叉：工作区干净时 `git pull --rebase`；有未提交改动先 `git stash push -u`，拉完 `git stash pop`。
   - 冲突：打开文件清干净 `<<<<<<<`、`=======`、`>>>>>>>`，`git add` 后 `git rebase --continue`。
2. **冲突清零后再提交。**
3. **推送前再确认**远端没有新提交，必要时先 `git pull --rebase`，再 `git push`。

本地落后或分叉时，插件的 PreToolUse 钩子会拦下 `git commit` 与 `git push` 并提示先拉取。钩子不改工作副本，拉取与解冲突由你手工完成。

## 冲突取舍

同一处两边改成不同内容、无法共存时，不替用户选：把两侧内容、涉及文件与提交信息列清楚，让用户决定。放弃变基用 `git rebase --abort` 前先跟用户确认，它会丢掉变基过程中已解决的改动。

提交信息怎么写、分支怎么建、历史怎么改，按用户当次要求处理，本插件不另定规则。
