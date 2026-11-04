# Java 注释做法

类头 Javadoc 见 `header-comment` 技能，本文只讲类内部的注释。

## 字段

```java
@ApiModelProperty(value = "按照,分割的ID字符串")
private String ids;
```

- 字段用 `@ApiModelProperty` 表达含义，**不要**在字段上写 Javadoc。
- 入参必填加 `required = true`。
- 禁止在字段上方再叠一行 `// 用户ID` 复述。注解已经写了。

## 方法与接口

```java
@ApiOperation("提醒消息分页列表")
@GetMapping("/page")
public JsonResult<PageResult<RemindMessage>> page(RemindMessageQuery query) {
```

- 控制层方法用 `@ApiOperation`。带复杂参数说明时可用 `@ApiOperation(value = ..., notes = ...)`，`notes` 写清业务口径，同样不要摊成一段。
- Service 内部方法、私有方法不加注解，也不写 Javadoc。方法名和签名能说明的事不必再写一遍。
- 不要为了"看起来很规范"给每个方法补 Javadoc——那是噪音，且与存量风格冲突。

## 行内注释

真实好例：

```java
// 查询即视为已读：查询后把当前单位所有未读消息标记为已读
remindMessageService.markAllRead();
```

这行讲的是代码看不出来的业务决定，值得留。同类内容要写两句以上时，说明这段知识该挪进命名或文档，不要继续往注释上叠。

该删的反例：

```java
// ==================== 用户相关 ====================

// 校验参数
if (StringUtils.isBlank(query.getId())) { ... }

// 循环遍历列表
for (RemindMessage m : list) { ... }

// TODO 🚀 待优化
// 2024-03-11 张三 新增查询条件
// private String oldField;

/** 构造方法 */
public UserServiceImpl() {}
```

- 分割线横幅：装饰，删。
- `// 校验参数`、`// 循环遍历列表`：复述代码，删。
- `TODO` 保留，emoji 去掉，补上要做什么。
- 变更履历：版本库已经记录了，删。
- 注释掉的死代码：删。要留就说明原因，否则它是垃圾。
- 简单方法上的 Javadoc：删。

## 边界

保存业务判断与口径的注释要留，但**留不等于写长**。以下是取自本仓库的真实例子，括号里是压缩后的写法：

`DoorRecordServiceImpl.java:173`（私有方法的 Javadoc——例外：这里的口径本身是知识，值得写。原来两行，压成一行）：

```java
/**
 * 登录人下辖的下级区域（省取市、市取区县），区县无下级时返回本级，无区域或区域码非法时返回空列表
 */
private List<SysRegion> listSubRegions() {
```

`RemindMessageController.java:43`（方法体内的行内注释）：

```java
// 查询即视为已读：查询后把当前单位所有未读消息标记为已读
remindMessageService.markAllRead();
```

判断标准有两条，先问留不留，再问长不长：**删掉这行，后来人会误改或看不懂吗？** 会就留；**留下的话，一行写得完吗？** 写不完就压到一行，压不下去又丢不得的报给用户。（同一套标准在 `trim-rules.md` 里也有，`comment-trimmer` 子代理以那份为准。）
