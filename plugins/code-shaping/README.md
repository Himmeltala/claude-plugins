# code-shaping

编码思维插件：写代码、改代码之前先想复用与参数形态。抽公共函数的理由只有"第二处要用"，长函数本身不算问题；同时不许过度抽象。

## 组件

| 组件 | 类型 | 作用 |
|---|---|---|
| `code-shaping` | 技能 | 判断清单：复用优先、拆只为公用、参数过长传对象、胶水代码泛化、模式用得其所、不许过度抽象 |
| `references/splitting.md` | 参考 | 该拆的信号、怎么拆、拆到什么程度、设计模式的位置 |
| `references/reuse-first.md` | 参考 | 动手前搜什么、该不该复用的判断表、复用不是硬凑 |

规范正文只在技能触发时加载，会话开始不再注入摘要。

## 安装

```bash
claude plugin install code-shaping@local-team
```

只想在部分项目里启用、其它项目不启用时，加 `-s project` 装到项目级（在项目目录下执行）：

```bash
claude plugin install code-shaping@local-team -s project
```


市场源地址、缓存机制与更新方式见仓库根目录的 `README.md`。

## 使用

写代码时自动遵守，也可以显式调用：

- 说"这段代码怎么拆"、"函数太长了要不要拆"、"能不能复用"、"参数太多"、"这里要不要上设计模式" —— 触发规则
- `/code-shaping:code-shaping` —— 显式走一遍判断清单

条目都是判断角度，不是硬性规定。按条款硬写代码反而别扭。
