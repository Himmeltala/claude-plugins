# input-guard

AI 输入检查插件：用户发来任务、代码、日志、数据时，先查敏感信息，再补全输入要素，最后从源头控制输入体积。只管输入侧。

## 组件

| 组件 | 类型 | 作用 |
|---|---|---|
| `input-guard` | 技能 | 三关检查：敏感信息、输入要素、token 源头控制；发请求时自动生效，也可显式调用 |
| `references/sensitive-data.md` | 参考 | 高敏感、个人信息、内部信息、生产数据的清单与脱敏处理 |
| `references/token-saving.md` | 参考 | 用路径代替内容、截取关键片段、不重复粘贴、拆小任务 |

规范正文只在技能触发时加载，会话开始不再注入摘要。

## 安装

```bash
claude plugin install input-guard@himmeltala-claude-plugins
```

只想在部分项目里启用、其它项目不启用时，加 `-s project` 装到项目级（在项目目录下执行）：

```bash
claude plugin install input-guard@himmeltala-claude-plugins -s project
```


市场源地址、缓存机制与更新方式见仓库根目录的 `README.md`。

## 使用

发任务时会自动检查，也可以显式调用：

- 说"检查一下这段输入"、"有没有敏感信息" —— 走敏感信息检查
- 说"输入太长了"、"贴太多了"、"token 太多" —— 走输入侧精简建议
- `/input-guard:input-guard` —— 显式走一遍三关检查

边界：只省用户输入给 AI 的内容，不压缩 AI 回复。回复结构与输出侧省 token 走 `output-guard`，措辞走 `chinese-writing`。发现疑似敏感信息先提醒，由用户决定是否继续。
