# code-testing

把代码测通的四段套路：没法真跑时用模拟服务在进程外把链路跑通，组件齐了用进程内假对端写端到端测试并按覆盖率补测，Java 里写这类测试的构建工具与 JVM 坑单独成一份，测试完成后把用例、结果、截图整理成交付用的表与报告。

## 组件

| 组件 | 类型 | 作用 |
|---|---|---|
| `mock-testing` | 技能 | 六步法：划边界、抄契约、写模拟服务、接管、三层验证、收尾还原。假对端是独立进程 |
| `coverage-testing` | 技能 | 五步法：定靶子、搭假对端、串真实链路、量覆盖补测、连跑验稳。假对端在测试代码里，同进程 |
| `java-testing` | 技能 | JUnit 5 写法、surefire 与 JaCoCo 配置、测试里起 socket 与线程的写法、反射覆盖防御分支 |
| `test-reporting` | 技能 | 测试用例表、测试报告、结果回填、终端截图与交付前校验 |
| `coverage-testing/references/` | 参考 | 假对端设计、未覆盖行的三分类与记账、偶发失败的三类根因 |
| `coverage-testing/examples/` | 参考 | 测试基建三件套（轮询等待、造数、目录断言）各自要满足什么 |
| `java-testing/references/` | 参考 | surefire 与 JaCoCo、socket 与线程写法、反射与分支覆盖 |
| `java-testing/examples/` | 模板 | 假对端骨架、测试基建骨架，各一份 Java 源码 |
| `test-reporting/references/` | 参考 | xlsx 用例表结构、DOCX 报告结构、证据捕获与截图规范 |
| `test-reporting/scripts/` | 工具 | 从 TSV 生成测试用例 xlsx，只依赖 Python 标准库 |
| `test-reporting/examples/` | 模板 | 纯黑框终端截图渲染器、Aspose 用例报告骨架 |
| `mock-testing/references/`、`mock-testing/examples/` | 参考与模板 | 契约清单模板、三层验证与踩坑清单；HTTP 模拟服务、假上游、WebSocket 观察器、起停脚本四份骨架 |

四个技能按需触发：只有名称与描述常驻上下文，正文与参考资料在触发后才加载。

## 安装

```bash
claude plugin install code-testing@local-team
```

只想在部分项目里启用、其它项目不启用时，加 `-s project` 装到项目级（在项目目录下执行）：

```bash
claude plugin install code-testing@local-team -s project
```


市场源地址、缓存机制与更新方式见仓库根目录的 `README.md`。

装过旧版本的注意：本插件早先叫 `mock-testing`，那个名字已撤掉，调用路径由 `/mock-testing:mock-testing` 变成 `/code-testing:mock-testing`。先卸再装：

```bash
claude plugin uninstall mock-testing@local-team
claude plugin install code-testing@local-team
```

## 使用

- **`/code-testing:mock-testing`** —— 对端没实现、不可达、缺硬件，要起独立进程的模拟服务把链路手工跑通。说"模拟一下"、"mock 这个接口"、"做个模拟服务"、"假云端"、"不连真环境跑通"、"故障注入"、"复现线上问题"时触发。
- **`/code-testing:coverage-testing`** —— 要写端到端测试把行为锁住、并把覆盖率补到目标。说"写端到端测试"、"把链路测通"、"覆盖率拉到 90%"、"按未覆盖行补测"、"连跑三轮"、"测试偶发失败"时触发。
- **`/code-testing:java-testing`** —— Java 项目里写与跑这些测试。说"写个 JUnit 测试"、"surefire 配置"、"JaCoCo 覆盖率"、"覆盖率报告没数据"、"测试卡住不退出"时触发。
- **`/code-testing:test-reporting`** —— 把测试结果整理成交付物。说"把测试用例整理成表"、"测试用例表"、"测试报告"、"测试执行报告"、"验收测试报告"、"测试结果汇总"、"回填测试结果"、"每条用例配截图"、"补测试截图"、"测试用例加截图"、"xlsx 测试用例"、"docx 测试报告"时触发。

分工的边界：**mock-testing 管进程外的模拟服务，coverage-testing 管进程内的假对端**。前者手工验一遍、摸清链路形状，后者把形状固化成能回归的用例。java-testing 只讲语言与构建工具的具体写法；test-reporting 只管用例表、报告、截图与结果口径，不重复测试设计。

模板以 Linux 与 JVM 或 Python 3 标准库为前提。`test-reporting/examples/` 的 DOCX 骨架依赖 Aspose.Words（商业 license，未配置会带评估水印），PDF 预览可选 PDFBox；其余示例不引第三方依赖。`java-testing/examples/` 的两份骨架改掉包名即可照抄；`test-reporting/scripts/` 的 xlsx 生成器从 TSV 直接出表，`test-reporting/examples/` 的黑框截图器与报告骨架按注释替换数据即可；其余边界类型照参考资料里的套路写。
