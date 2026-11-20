# Java 注释做法

类头 Javadoc 见 `header-comment`，本文只讲类内部。

## 字段

```java
@ApiModelProperty(value = "按照,分割的ID字符串")
private String ids;
```

- 字段用 `@ApiModelProperty`，不写 Javadoc，不在上方再叠 `// 用户ID`。必填加 `required = true`。

## 方法与接口

```java
@ApiOperation("提醒消息分页列表")
@GetMapping("/page")
public JsonResult<PageResult<RemindMessage>> page(RemindMessageQuery query) {
```

- 控制层方法用 `@ApiOperation`；复杂参数用 `value` 与 `notes`，notes 写业务口径，不摊成段。
- Service 内部方法与私有方法不加注解、不写 Javadoc——方法名与签名能说明的不必再写。
- 不给每个方法补 Javadoc，那是噪音，也与存量风格冲突。

## 行内注释

该留，讲代码看不出来的业务决定：

```java
// 查询即视为已读：查询后把当前单位所有未读消息标记为已读
remindMessageService.markAllRead();
```

要写两句以上时，说明该信息应挪进命名或文档。

该删：

```java
// ==================== 用户相关 ====================
// 校验参数
// 循环遍历列表
// TODO 🚀 待优化
// 2024-03-11 张三 新增查询条件
// private String oldField;
/** 构造方法 */
```

横幅是装饰；复述代码删；`TODO` 保留内容、去 emoji；变更履历与死代码删；简单方法 Javadoc 删。

## 边界

留业务口径，但留不等于写长，原来两行压成一行：

```java
/**
 * 登录人下辖的下级区域（省取市、市取区县），区县无下级时返回本级，无区域或区域码非法时返回空列表
 */
private List<SysRegion> listSubRegions() {
```

判断：删掉这行，后来人会误改或看不懂吗？会就留。留下的一行写得完吗？写不完压到一行，压不下去报给用户。
