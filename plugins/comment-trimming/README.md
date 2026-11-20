# comment-trimming

团队注释规范插件：注释怎么留、怎么清。

## 组件

| 组件 | 类型 | 作用 |
|---|---|---|
| `comment-trimming` | 技能 | 代码内部注释的写法与裁剪：默认不写、只讲本段代码、篇幅按中文规范、编辑文件时整文件顺手清干净 |
| `header-comment` | 技能 | 文件头与类头：Java 类头 Javadoc，前端文件头六字段块 |
| `comment-trimmer` | 子代理 | 整目录、整模块的存量注释批量清理，先出清单再动手 |

## 安装

```bash
claude plugin install comment-trimming@himmeltala-claude-plugins
```

只想在部分项目里启用时，在该项目目录下加 `-s project` 装到项目级：

```bash
claude plugin install comment-trimming@himmeltala-claude-plugins -s project
```

市场源地址、缓存机制与更新方式见仓库根目录的 `README.md`。

## 使用

- 说"注释太乱帮我清一下"：走 `comment-trimming` 的裁剪规则
- 说"把 xxx 模块的注释批量清掉"：派 `comment-trimmer` 子代理
- `/comment-trimming:comment-trimming`：显式走一遍规则
- 说"文件头怎么写"、"类头 Javadoc 怎么写"、"@Author 写谁"：触发 `header-comment`

篇幅数值以 `chinese-writing` 的篇幅标准为准，本插件只执行。
