---
name: comment-trimming
description: 编写、修改或审查 Java、Vue、JavaScript 代码，或处理 Mapper XML 与 SQL 注释时使用，管代码内部注释的写法与裁剪；文件头与类头注释见 `header-comment`。触发词：注释太乱、注释太多、注释太长、注释密密麻麻、注释占地方、清理注释、裁剪注释、压缩注释、精简注释、删注释、去掉 emoji、去掉分割线、注释里的箭头、注释规范、注释怎么写、注释掉的代码、死代码注释、TODO 注释、变更履历注释、Mapper XML 注释、SQL 注释、Vue 注释、JS 注释、Java 注释。
argument-hint: "[要处理的文件或目录]"
allowed-tools: [Read, Edit, Write, Grep, Glob, Bash]
---

# 代码注释规范：稀疏且简短

管代码内部注释；文件头与类头见 `header-comment` 技能。参数在 `$ARGUMENTS`：

- 文件：整文件范围清理。
- 目录：存量清理，派 `comment-trimmer` 子代理，先出清单。
- 无参数：正常遵守规范；本次编辑碰到的文件整文件顺手清干净。

## 五条硬规矩

1. **默认不写。** 能自解释就不加，只写非显然的"为什么"。
2. **短。** 篇幅按 `chinese-writing` 的篇幅标准，所有注释类型一样：`//`、字段与方法注解、Mapper XML 的 `--`、模板 `<!-- -->`。一行写不完，就把信息挪进命名、常量或文档。
3. **不用符号装饰。** 禁 emoji、`=====`/`*****` 分割线、ASCII 艺术、`★ ✅ 🚀`。
4. **不复述代码。** `setName()` 上写 `// 设置 name` 是噪音。也不写会随实现变化的内容。
5. **只讲本段代码。** 不写调用关系与调用链，要看就用编辑器查找引用。

**压短**：删解释链、举例、语气词，只留结论与关键字。承载业务口径的长注释也照压；压不下去又丢不得的列入报告让用户定。

**三类例外**：文件头与类头（写法见 `header-comment`）、功能性指令（`eslint-disable`、`@SuppressWarnings`、`//noinspection` 原样保留，只压里面的人话）、注解值（`@ApiModelProperty`、`@ApiOperation` 的 value 与 notes 属接口文档，同样不写长）。

符号规则以 `chinese-writing` 为准。注释里多一条边界：**字符串字面量与注解值里的符号是数据，一个字不动**。前端另有 eslint 规则拦符号，见 `references/symbol-rules.md`。

## 注释形式

Java、Vue、JS：`//`、`/* */`、`/** */`，模板用 `<!-- -->`；Mapper XML：SQL 用 `-- `，结构用 `<!-- -->`。

## 团队做法

| 文件 | 内容 |
|---|---|
| `references/java-conventions.md` | 字段 `@ApiModelProperty`、控制层方法 `@ApiOperation`、行内注释取舍 |
| `references/js-conventions.md` | 单行注释与函数 JSDoc |
| `references/symbol-rules.md` | 注释符号禁忌与两个规则缺陷 |
| `references/trim-rules.md` | 删什么、留什么、判断边界（权威） |

关键：Java 字段用 `@ApiModelProperty`，控制层方法用 `@ApiOperation`；Service 内部与私有方法不加注解、不补 Javadoc。存量是 Swagger 注解风格，新代码必须一致；新项目沿用，与存量冲突时先对齐再报给用户。

## 编辑文件时顺手裁剪

本次编辑碰到的文件，**整文件**清干净，不限改动的函数。边界：没编辑过的文件不碰——触发条件是"我在改这个文件"，不是"这个模块看着乱"。整文件一次清完，避免标准漂移。清理动到本次改动之外的注释时，在唯一那行提交信息里带上"顺带清理注释"。

永远不删：功能性指令、`TODO`/`FIXME`（只去装饰）、许可证头与类头 Javadoc。

裁剪后自查：还有乱注释吗、有超长注释吗、有调用链吗、动了没编辑的文件吗、误删功能指令吗、Javadoc 与注解动反了吗。

## 边界

只碰注释与空行，不改逻辑、不重构、不统一缩进或 import。单文件由主线程做；整目录、整模块才派 `comment-trimmer`，它先出清单，跳过 `node_modules/`、`target/`、`dist/`。

提交格式见 `commit-guarding` 的 `svn-commit` 技能。
