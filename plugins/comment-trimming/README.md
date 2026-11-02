# comment-trimming

团队注释规范插件：注释怎么留、怎么清。与版本控制、中文表达无关的部分都收敛在这里。

## 组件

| 组件 | 类型 | 作用 |
|---|---|---|
| `comment-trimming` | 技能 | 代码内部注释的写法与裁剪：稀疏优先、只讲本段代码、不复述实现细节、篇幅按中文规范；编辑某个文件时顺手把该文件整文件清干净 |
| `header-comment` | 技能 | 文件头与类头注释：Java 类头 Javadoc，以及 JS、CSS、HTML、Vue 文件头六字段块；作者取仓库配置、日期时间、路径、一句话描述 |
| `comment-trimmer` | 子代理 | 整目录、整模块的存量注释批量清理，先出清单再动手 |

规范正文只在技能触发时加载，会话开始不再注入摘要。

## 安装

```bash
claude plugin install comment-trimming@local-team
```

只想在部分项目里启用、其它项目不启用时，加 `-s project` 装到项目级（在项目目录下执行）：

```bash
claude plugin install comment-trimming@local-team -s project
```

DSH 侧是同一个目录的另一重身份，技能由包内 `lib/index.js` 注册：

```bash
dsh plugin --profile web add github:Himmeltala/local-team#path:/plugins/comment-trimming
```

改源码时换成 `./plugins/comment-trimming`。

市场源地址、缓存机制与更新方式见仓库根目录的 `README.md`。

## 使用

技能多数会自动触发，也可以显式调用：

- 说"注释太乱帮我清一下" —— 触发 `comment-trimming` 技能的裁剪规则
- 说"把 xxx 模块的乱注释批量清掉" —— 派 `comment-trimmer` 子代理，先出清单再动手
- `/comment-trimming:comment-trimming` —— 显式走一遍规则
- 说"文件头注释怎么写"、"类头 Javadoc 怎么写"、"@Author 写谁"、"给新文件补个头" —— 触发 `header-comment` 技能

触发词还包括"注释太多"、"注释太长"、"注释写了一大串"、"注释密密麻麻"、"注释一大堆"、"清理注释"、"裁剪注释"、"压缩注释"、"精简注释"、"整理注释"、"去掉 emoji"、"去掉分割线"、"注释里的箭头"、"注释规范"、"注释怎么写"、"注释掉的代码"、"Mapper XML 注释"、"SQL 注释"。注释的篇幅数值以 `chinese-writing` 插件的篇幅标准为准，本插件只执行。
