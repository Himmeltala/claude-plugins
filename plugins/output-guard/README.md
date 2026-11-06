# output-guard

AI 输出规范插件：按场景套用固定回复结构，同时约束输出侧的 token。与 `input-guard` 成对，一个管发进来的，一个管写出去的。

## 组件

| 组件 | 类型 | 作用 |
|---|---|---|
| `output-guard` | 技能 | 按场景选择模板并套用伸缩规则；输出侧省 token 规则始终适用 |
| `references/troubleshooting-reply.md` | 参考 | 排查与故障结论：现象、根因、证据、影响范围、修复方向 |
| `references/change-summary.md` | 参考 | 代码改动说明：改了什么、为什么改、影响范围、验证方式 |
| `references/progress-report.md` | 参考 | 进度与结果汇报：已完成、未完成或受阻、下一步 |
| `references/token-saving.md` | 参考 | 结论先行、不复述、只给相关片段、分轮输出、什么不能省 |

规范正文只在技能触发时加载，会话开始不再注入摘要。

## 安装

```bash
claude plugin install output-guard@local-team
```

只想在部分项目里启用、其它项目不启用时，加 `-s project` 装到项目级（在项目目录下执行）：

```bash
claude plugin install output-guard@local-team -s project
```


市场源地址、缓存机制与更新方式见仓库根目录的 `README.md`。

## 使用

技能按场景自动触发，也可以显式调用：

- 说"排查结论"、"根因是什么" —— 套用排查与故障结论模板
- 说"改了什么"、"改动说明" —— 套用代码改动说明模板
- 说"汇报一下"、"进度怎么样" —— 套用进度与结果汇报模板
- 说"输出太长了"、"回复太啰嗦"、"省点 token" —— 按输出侧规则压缩回复
- `/output-guard:output-guard` —— 显式走一遍输出规则

边界：省 token 不省证据；结论依赖的 SQL、日志行、文件位置必须给全。输入侧的敏感信息与冗余归 `input-guard`，中文措辞归 `chinese-writing`。
