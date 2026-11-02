---
name: comment-trimming
description: 当编写、修改或审查 Java、Vue、JavaScript 代码，或处理 Mapper XML 与 SQL 注释时使用，管代码内部注释的写法与裁剪；文件头与类头注释另见 `header-comment` 技能。触发词包括"注释太乱"、"注释太多"、"注释太长"、"注释写了一大串"、"注释密密麻麻"、"注释一大堆"、"注释占地方"、"清理注释"、"裁剪注释"、"压缩注释"、"精简注释"、"删注释"、"去掉注释"、"整理注释"、"把注释整理一下"、"去掉 emoji"、"去掉分割线"、"去掉装饰"、"注释里的箭头"、"这种横幅"、"注释规范"、"注释怎么写"、"注释怎么留"、"方法注释怎么写"、"字段注释怎么写"、"注释掉的代码"、"死代码注释"、"TODO 注释"、"变更履历注释"、"Mapper XML 注释"、"SQL 注释"、"Vue 注释"、"JS 注释"、"Java 注释"。
argument-hint: "[要处理的文件或目录]"
allowed-tools: [Read, Edit, Write, Grep, Glob, Bash]
---

# 代码注释规范：稀疏且简短

本技能管代码内部的注释；文件头与类头注释的写法见 `header-comment` 技能。

用户调用时带了参数，参数在用户消息里（Claude 端也会填进 `$ARGUMENTS`）。

- 参数是文件：清该文件的注释，整文件范围。
- 参数是目录：这是存量批量清理，交给子代理，先出清单再动手。Claude 派 `comment-trimmer`；DSH 用 `subagent` 工具，任务说明取 `../../agents/comment-trimmer.md`。
- 无参数：当前任务里正常遵守规范；本次编辑碰到的文件，按整文件范围顺手清干净。

## 五条硬规矩

1. **默认不写注释。** 代码能自解释的就不加。只有"为什么"非显然时才写。
2. **注释要短。** 篇幅按 `chinese-writing` 插件的篇幅标准执行，**所有注释类型都一样**：行内 `//`、字段与方法注解、Mapper XML 的 `--`、模板里的 `<!-- -->`。一行说不完，就说明这段信息不该待在注释里——挪进命名、常量或文档，不要写成一段。
3. **不用符号装饰。** 禁 emoji，禁 `=====`、`*****`、`-----` 分割线，禁 ASCII 艺术，禁 `★ ✅ ❌ 🚀` 这类无义装饰。
4. **注释不许复述代码。** 写在 `setName()` 上方的 `// 设置 name` 是噪音，删。注释也不写会随实现变化的内容，判据见 `chinese-writing` 的落盘产出第十条。
5. **只讲本段代码。** 不写调用关系与调用链（谁调用我、我调用谁、上游何时写入这个值、下游谁消费）。代码随时在改，关联注释跟不上重构，重构一次就多一处假话；要看调用关系用编辑器的查找引用。

**怎么压。** 删掉解释链条、举例与语气词，只留结论和关键字；一句话能说完的不拆两句，括号里补的解释挪进命名或文档。承载业务口径的长注释也照压，不许因为"信息重要"就留成一段——真压不下去又丢不得，在回复里列出来让用户定，不要自行删掉。

**注释特有的例外三种。** 文件头与类头注释（写法见 `header-comment` 技能，整块不动）、功能性指令（`eslint-disable`、`@SuppressWarnings`、`//noinspection` 按语法原样保留，压缩只碰里面的人话）、注解值（`@ApiModelProperty`、`@ApiOperation` 的 value 与 notes 属接口文档，不是注释，但同样不该写成长文）。

**符号规则以 `chinese-writing` 插件为准**（禁符号代字、禁箭头与箭头区、禁装饰符号，改写对照表与例外都在那边，本插件不另写一份）。注释里只多一条本层边界：**字符串字面量与注解值里的符号是数据，一个字不动**，详见 `references/trim-rules.md`。

前端另有更严的自定义 eslint 规则会拦符号，细则与两个真实的规则缺陷见 `references/symbol-rules.md`。

## 可用的注释形式

- Java：`//`、`/* */`、`/** */`
- Vue 与 JS：同上，模板用 `<!-- -->`
- Mapper XML：SQL 用 `-- `，结构层用 `<!-- -->`

## 按层的团队做法

各语言的具体模板、正反例、实测统计见引用文件，**不要凭印象发挥**：

- `references/java-conventions.md`——字段 `@ApiModelProperty`、方法 `@ApiOperation`、行内注释取舍（类头 Javadoc 见 `header-comment` 技能）
- `references/vue-js-conventions.md`——Vue 与 JS 的轻注释做法
- `references/symbol-rules.md`——注释符号禁止清单与两个规则缺陷

**关键**：Java 字段用 `@ApiModelProperty`，**控制层**方法用 `@ApiOperation`。Service 内部方法与私有方法不加注解、也不补 Javadoc。不要把这些统一改成 Javadoc——团队存量代码统一是 Swagger 注解那套，新代码必须一致。

**新项目照此执行。** 这套约定不绑定某个项目：新起的前后端仓库一律沿用，不要另立风格。若新项目已有既有写法且与本节冲突，先按项目存量对齐，再把冲突报给用户。

## 编辑文件时顺手裁剪

**本次编辑碰到哪个文件，就把那个文件里的密集乱注释一并清干净。** 裁剪范围是**整文件**，不再限定在改动的函数、方法或模板块内。

边界只有一条：**没编辑过的文件一律不碰**。触发条件是"我正在改这个文件"，不是"这个模块看着乱"。

这样定的理由是文件级一致性：清一半的文件比不清更麻烦——下一个改它的人得重新判断哪些注释该留，判断标准还会漂。整文件一次清完，从此是干净的基线。

代价是 diff 变大。只要清理动到了本次改动之外的注释，就在那唯一一行提交信息里带上"顺带清理注释"，别让清理变成隐形改动。提交信息不能另起一行说明（见 `commit-guarding` 插件的 `svn-commit` 技能）。

删什么、留什么、判断边界，以 `references/trim-rules.md` 为准——`comment-trimmer` 子代理也以同一份为准。三条永远不删：

- 功能性指令：`//noinspection`、`eslint-disable`、`@SuppressWarnings`、`@SuppressFBWarnings`
- `TODO`、`FIXME`——保留，仅去装饰
- 既有类级元信息：许可证头、类头 Javadoc（写法见 `header-comment` 技能）

裁剪后自查：该文件里是否还留着乱注释、是否还有超过篇幅上限的长注释、是否还留着调用关系与调用链的注释、是否动了本次没编辑的文件、是否误删功能性指令、是否把存量 Javadoc 改成注解或反过来。

## 边界

只碰注释与空行。不改代码逻辑，不重构，不统一缩进或 import 顺序。单文件顺手裁剪由主线程按整文件做；整目录、整模块的存量清理才派 `comment-trimmer`。

## 存量批量清理

整目录、整模块的注释清理交给子代理。Claude 用 `comment-trimmer`，DSH 用 `subagent` 工具带上 `../../agents/comment-trimmer.md` 的说明。它先出清单再动手，并跳过 `node_modules/`、`target/`、`dist/`。

## 附加资源

- `references/java-conventions.md`
- `references/vue-js-conventions.md`
- `references/symbol-rules.md`
- `references/trim-rules.md`——删什么、留什么、边界判断（裁剪的权威文件）

提交代码时同时遵守提交格式，见 `commit-guarding` 插件的 `svn-commit` 技能。
