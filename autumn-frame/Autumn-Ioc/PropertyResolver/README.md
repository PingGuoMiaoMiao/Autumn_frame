# PropertyResolver - 配置属性解析器

## 概述

PropertyResolver 是一个轻量级的配置管理工具，用于 Moonbit 语言实现 Spring 风格的属性注入功能。它提供了灵活的配置查询和类型转换功能。

## 功能特性

### 1. 三种查询方式

#### 1.1 普通 key 查询
```moonbit
let resolver = PropertyResolver::from_array([
  ("app.name", "Autumn Framework")
])

match resolver.get_property("app.name") {
  Some(v) => println(v)  // 输出: Autumn Framework
  None => println("未找到")
}
```

#### 1.2 ${key} 表达式查询
```moonbit
match resolver.get_property("${app.name}") {
  Some(v) => println(v)  // 输出: Autumn Framework
  None => println("未找到")
}
```

#### 1.3 ${key:default} 带默认值查询
```moonbit
// 存在的 key 返回实际值
resolver.get_property("${app.name:DefaultApp}")  // 返回: "Autumn Framework"

// 不存在的 key 返回默认值
resolver.get_property("${app.missing:DefaultValue}")  // 返回: "DefaultValue"
```

### 2. 嵌套查询

支持嵌套的 ${...} 表达式：

```moonbit
let resolver = PropertyResolver::from_array([
  ("APP_NAME", "Production"),
  ("app.title", "${APP_NAME}")
])

// 自动递归解析
resolver.get_property("app.title")  // 返回: "Production"

// 多层嵌套
resolver.get_property("${app.title:${APP_NAME:Default}}")
// 先查 app.title，没有则查 APP_NAME，都没有则返回 Default
```

### 3. 类型转换

#### 3.1 Int 类型
```moonbit
let resolver = PropertyResolver::from_array([
  ("server.port", "8080")
])

match resolver.get_property_int("server.port") {
  Some(port) => println(port)  // 8080 (Int)
  None => println("转换失败")
}
```

#### 3.2 Bool 类型
```moonbit
let resolver = PropertyResolver::from_array([
  ("debug.enabled", "true")
])

match resolver.get_property_bool("debug.enabled") {
  Some(enabled) => println(enabled)  // true (Bool)
  None => println("转换失败")
}
```

支持的 Bool 值：
- `true`: "true", "True", "TRUE", "1", "yes"
- `false`: "false", "False", "FALSE", "0", "no"

#### 3.3 Double 类型
```moonbit
let resolver = PropertyResolver::from_array([
  ("ratio", "3.14")
])

match resolver.get_property_double("ratio") {
  Some(r) => println(r)  // 3.14 (Double)
  None => println("转换失败")
}
```

### 4. 辅助方法

#### 4.1 带默认值的查询
```moonbit
let value = resolver.get_property_or_default("app.name", "默认应用")
// 如果 app.name 不存在，返回"默认应用"
```

#### 4.2 检查属性是否存在
```moonbit
if resolver.contains_property("app.name") {
  println("属性存在")
}
```

#### 4.3 获取所有属性名
```moonbit
let names = resolver.get_property_names()
for i = 0; i < names.length(); i = i + 1 {
  println(names[i])
}
```

#### 4.4 设置属性
```moonbit
resolver.set_property("new.key", "new value")
```

#### 4.5 注册自定义类型转换器
```moonbit
resolver.register_converter("MyType", fn(s) {
  // 自定义转换逻辑
  s.to_upper()
})
```

## API 参考

### 创建 PropertyResolver

```moonbit
// 从 HashMap 创建
pub fn PropertyResolver::new(properties : @hashmap.HashMap[String, String]) -> PropertyResolver

// 从数组创建
pub fn PropertyResolver::from_array(pairs : Array[(String, String)]) -> PropertyResolver
```

### 查询方法

```moonbit
// 获取 String 属性（可选）
pub fn get_property(self : PropertyResolver, key : String) -> String?

// 获取必需属性（不存在会打印错误）
pub fn get_required_property(self : PropertyResolver, key : String) -> String?

// 获取属性或默认值
pub fn get_property_or_default(
  self : PropertyResolver, 
  key : String, 
  default : String
) -> String

// 获取 Int 属性
pub fn get_property_int(self : PropertyResolver, key : String) -> Int?

// 获取 Bool 属性
pub fn get_property_bool(self : PropertyResolver, key : String) -> Bool?

// 获取 Double 属性
pub fn get_property_double(self : PropertyResolver, key : String) -> Double?
```

### 辅助方法

```moonbit
// 检查属性是否存在
pub fn contains_property(self : PropertyResolver, key : String) -> Bool

// 获取所有属性名
pub fn get_property_names(self : PropertyResolver) -> Array[String]

// 设置属性
pub fn set_property(self : PropertyResolver, key : String, value : String) -> Unit

// 注册类型转换器
pub fn register_converter(
  self : PropertyResolver,
  type_name : String,
  converter : (String) -> String
) -> Unit
```

## 使用示例

### 示例 1: 配置文件解析

```moonbit
// 模拟从配置文件读取
let config = PropertyResolver::from_array([
  ("app.name", "Autumn Framework"),
  ("app.version", "1.0"),
  ("server.host", "localhost"),
  ("server.port", "8080"),
  ("debug", "true")
])

// 获取配置
let app_name = config.get_property_or_default("app.name", "Unknown")
let port = config.get_property_int("server.port")
let debug = config.get_property_bool("debug")
```

### 示例 2: 环境变量支持

```moonbit
// 模拟环境变量和配置的合并
let config = PropertyResolver::from_array([
  // 环境变量（优先级高）
  ("DB_HOST", "prod-db.example.com"),
  ("DB_PORT", "5432"),
  
  // 应用配置
  ("db.url", "jdbc:postgresql://${DB_HOST}:${DB_PORT}/mydb"),
  ("db.username", "${DB_USER:admin}"),
  ("db.password", "${DB_PASS:secret}")
])

// 自动解析嵌套变量
match config.get_property("db.url") {
  Some(url) => println(url)
  // 输出: jdbc:postgresql://prod-db.example.com:5432/mydb
  None => ()
}
```

### 示例 3: Spring 风格的 @Value 注入

```moonbit
// 模拟 @Value 注解的使用
struct AppConfig {
  app_name : String
  version : String
  port : Int
  debug : Bool
}

fn create_app_config(resolver : PropertyResolver) -> AppConfig {
  {
    app_name: resolver.get_property_or_default("${app.name:MyApp}", "Default"),
    version: resolver.get_property_or_default("${app.version:1.0}", "1.0"),
    port: resolver.get_property_int("${server.port:8080}").or(8080),
    debug: resolver.get_property_bool("${debug:false}").or(false)
  }
}
```

## 与 Java Spring 的对比

| 特性 | Spring PropertyResolver | Moonbit PropertyResolver |
|------|------------------------|--------------------------|
| 基本 key 查询 | ✅ | ✅ |
| ${key} 查询 | ✅ | ✅ |
| ${key:default} | ✅ | ✅ |
| 嵌套查询 | ✅ | ✅ |
| 组合表达式 | ✅ jdbc:mysql://${HOST}:${PORT}/${DB} | ❌ 不支持 |
| #{...} 表达式 | ✅ SpEL | ❌ 不支持 |
| 类型转换 | ✅ | ✅ Int, Bool, Double |
| 自定义转换器 | ✅ | ✅ |
| 环境变量 | ✅ 自动合并 | ✅ 手动合并 |

## 限制

### 1. 不支持组合表达式

```moonbit
// ❌ 不支持这种组合
"jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}"

// ✅ 需要分别解析每个变量
let host = resolver.get_property("DB_HOST")
let port = resolver.get_property("DB_PORT")
let db = resolver.get_property("DB_NAME")
let url = "jdbc:mysql://" + host.or("localhost") + ":" + 
          port.or("3306") + "/" + db.or("mydb")
```

### 2. 不支持 #{...} SpEL 表达式

```moonbit
// ❌ 不支持 Spring Expression Language
"#{appBean.version() + 1}"

// ✅ 需要在代码中实现逻辑
let version = resolver.get_property_int("app.version").or(1)
let next_version = version + 1
```

## 测试

运行测试：

```bash
moon build && moon run property-test
```

测试覆盖：
- ✅ 基本查询
- ✅ ${key} 表达式查询
- ✅ ${key:default} 带默认值查询
- ✅ 嵌套查询
- ✅ Int/Bool/Double 类型转换

## 性能特点

- **查询性能**: O(1) HashMap 查找
- **嵌套解析**: 递归深度取决于嵌套层数
- **类型转换**: 手动实现，无外部依赖
- **内存占用**: 仅存储配置的 HashMap

## 依赖

- `@hashmap` (Moonbit 标准库)

## 作者

GitHub Copilot

## 许可证

Apache-2.0
