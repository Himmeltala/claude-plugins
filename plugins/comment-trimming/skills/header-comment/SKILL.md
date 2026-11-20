---
name: header-comment
description: 新建或修改 Java、JS、CSS、HTML、Vue 文件，需要补齐或更新文件头注释时使用。触发词：文件头注释、头文件注释、补个文件头、加文件头、类头 Javadoc、@author 写谁、@since、@version、@FilePath、@Description、文件头怎么写、新建文件要加头吗。
argument-hint: "[要处理的文件或目录]"
allowed-tools: [Read, Edit, Write, Grep, Glob, Bash]
---

# 头文件注释规范

## JS、CSS、HTML、Vue

`.html` 与 `.vue` 用 `<!-- -->`，`.js` 与 `.css` 用 `/* ... */` 包同一套字段：

```html
<!--
 * @Author: <仓库配置的作者>
 * @Date: 2026-07-14 01:46:05
 * @LastEditors: <仓库配置的作者>
 * @LastEditTime: 2026-08-05 08:48:17
 * @FilePath: \src\App.vue
 * @Description: <一句话描述文件职责>
-->
```

- 六字段固定顺序，缺一不可。
- `Author`/`LastEditors` 用仓库配置作者：git 查 `git config user.name`，SVN 用提交账号；查不到就问，不要猜。
- 新建时两者都写当前作者；改动已有文件只更新 `LastEditors` 与 `LastEditTime`。
- 时间写全 `YYYY-MM-DD HH:MM:SS`。
- `FilePath` 用反斜杠相对路径，如 `\src\App.vue`。
- `Description` 同一行一句话，写不出就留空。
- 裁剪时整块不动；要更新按现有值改，或交给 eslint `--fix`。

## Java 类 Javadoc

```java
/**
 * 提醒消息服务，负责未读数量统计与标记已读。
 *
 * <p>标记已读按单位维度批量处理，不区分具体消息。
 *
 * @author 张三
 * @since 1.0.0
 * @version 1.0.0
 */
public class RemindMessageService {
```

- 第一句摘要独立成句，说清类职责。
- 补充用 `<p>`，只写非显然的口径、单位、坑、约束；不写调用关系。
- `@author`：新建用仓库配置用户名，已有类保留原值。
- `@since`：项目版本号，无版本体系时写首次提交日期。
- `@version`：当前版本号，与 `@since` 同体系；不用版本号可省。
- 不用 `@title`、`@description`、`@date`、`@LastEditors`、`@FilePath`，修改记录交给版本控制。
