---
name: java-testing
description: 当在 Java 项目里写测试、跑测试，或调 surefire 与 JaCoCo 时使用。触发词包括"写个 JUnit 测试"、"mvn test 跑不起来"、"surefire 配置"、"JaCoCo 报告没数据"、"覆盖率报告是空的"、"覆盖率统计把整个工程算进分母"、"forkCount"、"测试卡住不退出"、"测试里用反射"。测试设计在 coverage-testing，本技能只管 Java 与构建工具的具体写法。
argument-hint: "[要写的测试类、要调的构建配置或覆盖率工具问题]"
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---

# Java 里写与跑测试

用户调用时带了参数，参数在用户消息里，也填进 `$ARGUMENTS`。

- 参数是测试类或模块：从第 1 步走。
- 参数是构建或覆盖率工具问题：直接跳第 4 步，按症状查下面的表和 `references/`。
- 无参数：先问清项目用的是 JUnit 4 还是 5、有没有 surefire 与 JaCoCo，再动手。

## 四步

1. **认环境。** 看 pom 或 build.gradle，确认测试依赖是 `spring-boot-starter-test` 还是手写的 `junit-jupiter`，surefire 是哪个版本，有没有 JaCoCo 插件。版本决定写法，尤其 surefire 低于 2.22 时 JUnit 5 根本不会被跑（测试全绿但一条没执行）。
2. **写用例。** JUnit 5 下测试类与方法包私有即可，不必 `public`。方法名直接写断言的行为，中文也行。每条用例自己造环境、自己收尾，用 `@AfterEach` 兜住清理。进程内假对端与测试基建的骨架见 `examples/`，改掉包名即可照抄。
3. **跑一遍。** `mvn -B test`。看的是用例数与耗时，不是退出码：失败会打印，**一条都没跑起来却显示 BUILD SUCCESS 才是真麻烦**。
4. **量覆盖率。** 先拿基线再补测。JaCoCo 可以不改 pom、用命令行直接调，见 `references/surefire-and-jacoco.md`。

## 与 coverage-testing 的分界

本技能只管 Java 与构建工具的具体写法：认环境、写用例、跑 `mvn test`、量覆盖率、排 surefire 与 JaCoCo 的坑。测试怎么设计、覆盖率怎么补，一律归 `coverage-testing` 技能；测试用例表、测试报告与执行截图归 `test-reporting` 技能，本技能不复述。

## 三条硬规矩

1. **测试自己起的东西自己关。** 见 `references/async-and-sockets.md` 的「线程收尾」。
2. **临时资源用系统给的。** 临时目录与端口都别写死，见 `references/async-and-sockets.md`。
3. **不要为验证语法反复构建。** 一次 `mvn test` 几十秒，改一行跑一次纯属浪费。攒够改动再跑，或者只跑相关用例。

## 常见坑

| 症状 | 多半是 |
|---|---|
| 用例数 0、BUILD SUCCESS | surefire 版本太低不认 JUnit 5，或测试类没在 `src/test/java` 下 |
| 覆盖率报告为空 | 构建配了 `forkCount=0`，agent 没挂上；或 agent 与 JVM 版本不匹配 |
| `mvn test` 不退出 | 测试里起的线程池是非 daemon 且没关 |
| 控制台看不到测试日志 | surefire 开了 `redirectTestOutputToFile`，日志在 `target/surefire-reports/*-output.txt` |
| 用例偶发红 | 见 `coverage-testing` 技能的 `references/stability.md` |
| 大报文用例特别慢 | 某处把 socket 接收缓冲压小了，见 `references/async-and-sockets.md` |

## 资源索引

- **`references/surefire-and-jacoco.md`** — surefire 与 JUnit 5 的搭配、测试日志去哪找、`forkCount=0` 时怎么挂 JaCoCo、报告怎么读
- **`references/async-and-sockets.md`** — 测试里起 socket 与线程：端口、临时目录、线程收尾、接收缓冲的副作用、写成功不等于对方读到
- **`references/branch-coverage.md`** — 用反射覆盖防御分支的写法与边界
- **`examples/FakeThirdParty.java`** — 进程内假对端骨架：收字节、记连接次数、主动断开、只连不读
- **`examples/ForwardTestSupport.java`** — 测试基建骨架：轮询等待、造数、目录断言、取空闲端口
