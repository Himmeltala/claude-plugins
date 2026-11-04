---
name: header-comment
description: 当新建或修改 Java、JS、CSS、HTML、Vue 文件，需要补齐或更新文件头注释时使用。触发词包括"文件头注释"、"头文件注释"、"补个文件头"、"加文件头"、"类头 Javadoc"、"@author 写谁"、"@since"、"@version"、"@Author"、"@LastEditors"、"@FilePath"、"@Description"、"文件头怎么写"、"Description 怎么写"、"新建文件要加头吗"。
argument-hint: "[要处理的文件或目录]"
allowed-tools: [Read, Edit, Write, Grep, Glob, Bash]
---

# 头文件注释规范

## JS、CSS、HTML、Vue

文件头统一使用下面这块注释。`<!-- -->` 是 `.html` 与 `.vue` 的写法；`.js` 与 `.css` 用 `/* ... */` 包同一套六字段，内容不变：

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

- 字段六项，顺序固定，缺一不可：`Author`、`Date`、`LastEditors`、`LastEditTime`、`FilePath`、`Description`。
- `@Author` 与 `@LastEditors` 用仓库配置的作者，不要写别的名字：git 仓库查 `git config user.name`，SVN 用该工作副本的提交账号。仓库没配或查不到时问用户，不要猜。
- 新建文件时 `Author` 与 `LastEditors` 都写当前配置的作者；改动已有文件时只更新 `LastEditors` 与 `LastEditTime`。
- 日期与时间写全 `YYYY-MM-DD HH:MM:SS`，只写日期不算完整。
- `FilePath` 用反斜杠写相对路径，例如 `\src\App.vue`。
- `@Description` 写在同一行，一句话说清这个文件负责什么。不换行、不分段、不摊成长段；没有可写的就留空。
- 裁剪注释时这一块整块不动：不删字段、不改顺序、不重写。需要更新时按现有值改，或整块交给 eslint 的 `--fix`。
- 新建的 `.js`、`.css`、`.html`、`.vue` 文件同样按此补齐。

## Java 类 Javadoc

Java 没有文件头注释，职责信息写在类声明的 Javadoc 上：

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

- 第一句是摘要，独立成句，一句话说清这个类负责什么。
- 补充细节另起 `<p>`，只在有非显然内容时写：口径约定、单位与精度、已知的坑、本类自己的约束。没有就不写，不要留空占位。不写调用关系与调用链（谁调用它、它写的数据谁消费），那类信息用查找引用来查。
- `@author` 写作者：新建类用仓库配置的用户名（git 查 `git config user.name`，SVN 用提交账号）；已有类保留原值，不要改成自己的名字。
- `@since` 写这个类从哪个版本开始有，填项目的版本号；没有版本体系时写首次提交的日期。
- `@version` 写当前版本号，与 `@since` 同体系；项目不用版本号时可省略。
- 不用 `@title`、`@description`、`@date`、`@LastEditors`、`@FilePath`：这些不是 Javadoc 标准标签，修改记录由版本控制承担。
