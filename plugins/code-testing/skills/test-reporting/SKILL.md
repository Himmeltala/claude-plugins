---
name: test-reporting
description: 本技能应在用户要求生成或回填测试用例表、测试报告，或为已执行用例配终端截图时使用；即使用户只说“把测试结果整理一下”“整理成交付文档”，只要需要表格、报告或截图，也应使用。触发词包括“测试用例表”“把测试用例整理成表”“测试报告”“测试执行报告”“验收测试报告”“测试结果汇总”“测试记录表”“回填测试结果”“每条用例配截图”“补测试截图”“测试用例加截图”“xlsx 测试用例”“docx 测试报告”。本技能负责交付物格式、结果口径、证据组织与截图；测试设计归 coverage-testing，测试代码的编写与运行归 java-testing；本技能只为出报告执行既有命令取证。
argument-hint: "[测试用例表、测试报告或要补截图的用例范围]"
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---

# 测试用例与测试报告

用户调用时带了参数，参数在用户消息里，也填进 `$ARGUMENTS`。

- 参数是测试用例表或报告：先确认格式、范围与结果口径，再按下面的流程生成。
- 参数是补截图：先读已有用例表或报告，确认编号、结果与缺图范围，再跳第 4 步。
- 参数是只补报告：已有用例表与结果时，跳过第 2、3 步，按第 5 步生成。
- 无参数：先问清交付格式、用例来源、结果状态、截图内容。

## 与其它技能的分界

本技能只管交付物：用例表、测试报告、执行截图、结果回填与校验。测试怎么设计、覆盖率怎么补，归 `coverage-testing`；Java 里怎么写与跑测试，归 `java-testing`；模拟服务与假对端分别归 `mock-testing` 与 `coverage-testing`。

## 前置条件

- JDK 8 及以上与 Maven 3；终端截图运行在 headless AWT，加 `-Djava.awt.headless=true`。
- 中文字体：Debian/Ubuntu 执行 `sudo apt install fonts-noto-cjk fonts-wqy-microhei`，再执行 `fc-cache -f`；Windows 用宋体或微软雅黑。
- DOCX 示例依赖 Aspose.Words 与有效 license；不配 license 时生成的报告会带评估水印。
- PDF 页面渲染与证据探针可用 PDFBox 2.0.x。
- 示例中的组件名、JAR 名、探针名、工作目录均为占位，按当前项目替换。
- 示例随插件安装；生成的用例表、报告与截图写在 `~/docs`，换机器不会自动带过去。

## 五步

1. **定口径。** 先确认三件事：交付格式（xlsx、docx）、用例来源（已有表、测试类）、结果口径（通过、未通过、未执行如何记）。用户说“没 BUG 就算通过”时，已执行且未发现缺陷的按通过记；未执行不能写通过，按用户要求删除或单列。不得自行把未执行写成通过，也不得删除失败行来让报告变绿。
2. **建用例表。** 按用户给的模板或 `references/test-case-workbook.md` 的列结构写：功能模块、功能点、编号、用例描述、前提条件、操作步骤、预期输出、优先级、测试结果、BUG描述、日期、用例编写人、测试人员。编号连续，模块与功能点合并单元格，用例总数与表内行数一致。没有模板时用 `scripts/write_test_case_xlsx.py` 生成。
3. **跑证据。** 每条用例对应一个可复现命令或测试方法。只为取证执行既有命令与测试方法，不设计也不新写测试。命令行用例跑真实命令，接口用例跑 `mvn -B -Dtest='Class#method' test`，转换类用例同时输出页数、图片数、水印、文字等校验结果。捕获 stdout、stderr 与退出码，保留原样。不要凭记忆编输出。
4. **做截图。** 默认只截终端结果，不截 PDF 页面。终端截图就是一个纯黑框，里面只有命令与输出；不加用例标题栏、不加模块名、不加“测试结果：通过”底栏、不截图外说明。终端用 `Noto Sans Mono CJK SC` 或 `WenQuanYi Micro Hei Mono`，PDF 页面用 `Noto Sans CJK SC`。只有用户明确要 PDF 页面或界面截图时才改用 PDFBox 渲染或界面截图。手工界面测试不适用终端截图流程，按用户提供的操作截图与步骤归档。
5. **生成报告。** 按 `references/test-report-docx.md` 生成 DOCX：封面、结果汇总、每条用例的标题、模块、前提、步骤、预期、测试方法、测试结果、黑框截图。每条用例一页，图片按页面可用高度缩放。生成后校验用例数、图片数、编号连续与 DOCX 完整性。

## 硬规矩

1. **截图只放真实输出。** 命令、输出、退出码必须来自实际执行。显示时可以缩短绝对路径，但不能改写结果。
2. **结果只写实际状态。** 已执行且未发现缺陷的写通过，未通过就写未通过，未执行按用户口径删除或单列。不把“部分通过”长期留在表里，除非用户明确要求；不得删掉失败行或改测试结果来让报告全绿。
3. **先解决字体，再截图。** headless 环境没有中文字体时，终端截图与 PDF 中文都会缺字形。装 `Noto Sans CJK SC` 或 `WenQuanYi Micro Hei` 后再截图，或明确告知用户未装字体。
4. **交付物放到 `~/docs/<项目>/<YYYY-MM-DD>/`。** 用例表、报告、截图目录放在同一日期目录；不放进源码目录，不执行 `svn add` / `git add`。
5. **报告与用例表一致。** 用例标题、编号、优先级、结果必须同源。删行后同步重编号、重算总数、重算模块统计。

## 常见坑

| 症状 | 多半是 |
|---|---|
| 环境里没有 openpyxl，xlsx 写不出来 | 用 Python 标准库 zipfile 直接写 SpreadsheetML，见 `references/test-case-workbook.md` |
| Excel 打开提示内容有问题 | inlineStr 未转义、合并单元格计数不对、dimension 范围不对 |
| 终端截图中文变方块 | AWT 找不到中文字体；安装 Noto CJK 或 WenQuanYi，按字体名取 Font |
| 截图里出现标题栏、通过底栏 | 渲染器画了多余装饰；只保留黑底、命令、输出 |
| 命令太长把截图撑满 | 显示时把绝对 java、jar、classpath 路径缩短为 `java`、`<组件>.jar`、`<证据探针>`，并在报告里保留完整命令 |
| Maven 输出太长 | 只保留 `Running`、`Tests run`、`BUILD`、`[ERROR]` 行 |
| DOCX 里图片过大被推到下一页 | 图片最大高度按页面可用高度算，通常不超过 13 至 14 厘米 |
| DOCX 图片下方文字从右侧开始 | `insertImage` 后先插入空段落，再写说明或分页 |
| DOCX 中文预览缺字形 | DOCX 存的是字体名；Linux 预览时给宋体加 Noto CJK 替换，Windows 用宋体打开正常 |
| PDF 报告误判带评估水印 | 文本里有 `Aspose.Words` 字样，不等于水印；检查 `Evaluation Only` 与页面渲染 |
| 截图里全是渐变测试图 | 把 PDF 页面或测试图片当成了执行证据；用户要终端结果时改成实际命令输出黑框 |

## 资源索引

以下示例以 word2pdf 组件为样本；换项目时替换命令、组件名与证据探针，不要照抄项目路径。

- **`scripts/write_test_case_xlsx.py`** — 从 TSV 生成带样式、合并、用例总数的 xlsx，只依赖 Python 标准库
- **`references/test-case-workbook.md`** — xlsx 用例表结构、列宽、合并、状态口径与校验
- **`references/test-report-docx.md`** — DOCX 报告结构、用例与证据映射、终端截图渲染、Aspose 插图、生成后校验
- **`references/evidence-capture.md`** — 命令与 Maven 输出捕获、路径显示规范化、退出码与预期异常的表达
- **`examples/TerminalShot.java`** — 纯黑框终端截图渲染器骨架，只画命令与输出
- **`examples/ReportBuilder.java`** — Aspose.Words 生成用例报告的骨架，含封面、汇总、逐条用例与截图
