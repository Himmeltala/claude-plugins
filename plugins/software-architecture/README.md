# software-architecture

团队代码架构规范插件：管复杂度，让代码随需求可预测地演进。

不绑定具体框架或设计模式。核心是四条：清晰边界、单向数据流、组合优于配置、质量约束前置。前端部分按框架无关的判据写，不绑定具体框架。

## 组件

| 组件 | 类型 | 作用 |
|---|---|---|
| `software-architecture` | 技能 | 通用层：四支柱、判断顺序、症状分诊、评审五问；前端细节转交下一个技能 |
| `frontend-architecture` | 技能 | 前端层：状态归属、单向数据流、组件组合、目录与依赖方向、默认阈值、质量门禁 |

无钩子、无子代理、无 MCP 服务器。

## 安装

```bash
claude plugin install software-architecture@himmeltala-claude-plugins
```

只想在部分项目里启用时，在该项目目录下加 `-s project` 装到项目级：

```bash
claude plugin install software-architecture@himmeltala-claude-plugins -s project
```

市场源地址、缓存机制与更新方式见仓库根目录的 `README.md`。

## 使用

技能自动触发，也可以显式调用：

- 说“这个模块该怎么分层”“依赖方向怎么定”“要不要抽象”：走 `software-architecture` 的总判据
- 说“组件太大了怎么拆”“状态放哪合适”“前端目录怎么分”“请求层怎么收”：走 `frontend-architecture`
- `/software-architecture:software-architecture`：显式过一遍通用判据
- `/software-architecture:frontend-architecture`：显式过一遍前端判据

## 与相邻插件的边界

- `frontend-design`（官方）：管视觉、排版、审美；本插件管代码结构与可维护性。
- `code-simplifier`、`code-review`：通用代码质量审查；本插件只管边界、数据流、状态、组合与可测试性。
- `comment-trimming`：管注释；与本插件不重叠。

## 扩展

后端等出现真实需求时，在同一插件下增加 `skills/backend-architecture/`，复用通用层判据，不提前预留空目录。
