# ApplicationContext - IoC 容器集成

## ✅ 完成状态

ApplicationContext 是 Autumn IoC 容器的核心，**真正集成了三个基础模块**：

1. **PropertyResolver** - 配置管理
2. **ResourceResolver** - 资源扫描
3. **BeanDefinition** - Bean 定义

## 🏗️ 架构图

```
┌─────────────────────────────────────────────────┐
│         ApplicationContext (IoC 容器)            │
├─────────────────────────────────────────────────┤
│                                                   │
│  ┌──────────────────┐                            │
│  │ PropertyResolver  │  ← 管理配置属性           │
│  │                   │     ${key}表达式解析      │
│  │                   │     类型转换              │
│  └──────────────────┘                            │
│                                                   │
│  ┌──────────────────┐                            │
│  │ ResourceResolver  │  ← 扫描资源文件           │
│  │                   │     .mbt文件查找          │
│  │                   │     多路径支持            │
│  └──────────────────┘                            │
│                                                   │
│  ┌──────────────────┐                            │
│  │ BeanDefinition    │  ← Bean定义数据结构       │
│  │ (HashMap)         │     按order排序           │
│  │                   │     Primary支持           │
│  │                   │     生命周期管理          │
│  └──────────────────┘                            │
│                                                   │
└─────────────────────────────────────────────────┘
```

## 📦 核心功能

### 1. 配置管理（PropertyResolver集成）

```moonbit
// 创建容器时传入配置
let config = [
  ("app.name", "MyApp"),
  ("db.port", "3306"),
  ("cache.enabled", "true")
]

let ctx = ApplicationContext::new(config, "com.example")

// 获取配置
ctx.get_property("app.name")           // Some("MyApp")
ctx.get_property_int("db.port")        // Some(3306)
ctx.get_property_bool("cache.enabled") // Some(true)
```

### 2. Bean 注册和管理（BeanDefinition集成）

```moonbit
// 注册 Bean
ctx.register_bean(
  "dataSource",              // Bean 名称
  "com.example.DataSource",  // Bean 类型
  10,                        // order（优先级）
  true                       // primary
)

// 查找 Bean
match ctx.find_bean("dataSource") {
  Some(def) => {
    println("找到 Bean: \{def.get_name()}")
  }
  None => println("Bean 不存在")
}
```

### 3. Bean 实例创建（按顺序）

```moonbit
// 创建单个 Bean
ctx.create_bean("dataSource")

// 创建所有 Bean（自动按order排序）
ctx.create_all_beans()

// 验证Bean是否已创建
match ctx.find_bean("dataSource") {
  Some(def) => {
    if def.has_instance() {
      println("Bean已创建")
    }
  }
  None => ()
}
```

### 4. 容器状态查看

```moonbit
ctx.print_summary()
// 输出：
// === ApplicationContext 状态 ===
// Bean 定义数量: 5
// 已创建实例: 5
// 
// --- Bean 列表 ---
//   dataSource: com.example.db.DataSource [已创建]
//   userService: com.example.service.UserService [已创建]
//   ...
```

## 🎯 API 文档

### 创建容器

```moonbit
pub fn ApplicationContext::new(
  config_properties : Array[(String, String)],
  base_package : String
) -> ApplicationContext
```

### Bean 管理

```moonbit
// 注册 Bean（构造函数方式）
pub fn register_bean(
  self : ApplicationContext,
  name : String,
  bean_class : String,
  order : Int,
  primary : Bool
) -> Unit

// 查找 Bean
pub fn find_bean(
  self : ApplicationContext,
  name : String
) -> @BeanDefinition.BeanDefinition?

// 创建 Bean
pub fn create_bean(
  self : ApplicationContext,
  name : String
) -> Bool

// 创建所有 Bean
pub fn create_all_beans(
  self : ApplicationContext
) -> Unit
```

### 配置访问

```moonbit
// 获取配置（String）
pub fn get_property(
  self : ApplicationContext,
  key : String
) -> String?

// 获取 Int 配置
pub fn get_property_int(
  self : ApplicationContext,
  key : String
) -> Int?

// 获取 Bool 配置
pub fn get_property_bool(
  self : ApplicationContext,
  key : String
) -> Bool?
```

### 容器信息

```moonbit
// 打印容器摘要
pub fn print_summary(
  self : ApplicationContext
) -> Unit
```

## 🚀 快速开始

### 1. 创建配置文件 `moon.pkg.json`

```json
{
  "is-main": true,
  "import": [
    {
      "path": "username/Autumn_frame/autumn-frame/Autumn-Ioc/ApplicationContext",
      "alias": "ApplicationContext"
    }
  ]
}
```

### 2. 编写代码

```moonbit
fn main {
  // 1. 准备配置
  let config = [
    ("app.name", "MyApp"),
    ("db.host", "localhost"),
    ("db.port", "3306")
  ]
  
  // 2. 创建容器
  let ctx = @ApplicationContext.ApplicationContext::new(
    config,
    "com.example"
  )
  
  // 3. 注册 Bean
  ctx.register_bean("userService", "com.example.UserService", 1, false)
  ctx.register_bean("orderService", "com.example.OrderService", 2, false)
  
  // 4. 创建所有 Bean
  ctx.create_all_beans()
  
  // 5. 查看状态
  ctx.print_summary()
}
```

### 3. 运行

```bash
moon run your-package
```

## 📝 完整示例

查看 `integration-demo/main.mbt` 获取完整的集成示例，包括：

- ✅ PropertyResolver 的使用（配置管理）
- ✅ BeanDefinition 的使用（Bean 定义）
- ✅ ApplicationContext 的使用（容器管理）
- ✅ Bean 按 order 排序创建
- ✅ @Primary 支持
- ✅ Bean 实例管理

运行示例：

```bash
moon run integration-demo
```

## 🎯 输出示例

```
============================================================
Autumn IoC 容器集成示例
============================================================

📝 第一步：准备配置属性
────────────────────────────────────────────────────────────
✓ 准备了 10 个配置项

🏗️  第二步：创建 ApplicationContext
────────────────────────────────────────────────────────────
✓ ApplicationContext 创建成功
  - PropertyResolver: 已加载
  - ResourceResolver: 已加载
  - Bean 容器: 已初始化

⚙️  第三步：测试 PropertyResolver 功能
────────────────────────────────────────────────────────────
✓ app.name = MyApplication
✓ app.version = 1.0.0
✓ db.port = 3306 (Int)
✓ cache.ttl = 600 秒 (Int)
✓ cache.enabled = true (Bool)

📦 第四步：注册 Bean 定义
────────────────────────────────────────────────────────────
✓ 注册 Bean: dataSource (order=10, primary=true)
✓ 注册 Bean: transactionManager (order=20)
✓ 注册 Bean: userService (order=30)
✓ 注册 Bean: orderService (order=30)
✓ 注册 Bean: userController (order=40)

🔨 第五步：创建 Bean 实例（按顺序）
────────────────────────────────────────────────────────────
创建 Bean: dataSource (com.example.db.DataSource)
创建 Bean: transactionManager (com.example.db.TransactionManager)
创建 Bean: userService (com.example.service.UserService)
创建 Bean: orderService (com.example.service.OrderService)
创建 Bean: userController (com.example.controller.UserController)

📊 第六步：查看容器状态
────────────────────────────────────────────────────────────
=== ApplicationContext 状态 ===
Bean 定义数量: 5
已创建实例: 5

--- Bean 列表 ---
  dataSource: com.example.db.DataSource [已创建]
  transactionManager: com.example.db.TransactionManager [已创建]
  userService: com.example.service.UserService [已创建]
  orderService: com.example.service.OrderService [已创建]
  userController: com.example.controller.UserController [已创建]

--- 配置属性示例 ---
  app.name = MyApplication
  app.version = 1.0.0

✅ 第七步：验证 Bean 是否正确创建
────────────────────────────────────────────────────────────
✓ dataSource: 已创建实例
  - 类型: com.example.db.DataSource
  - Primary: true
  - Order: 10

✓ userService: 已创建实例
  - 类型: com.example.service.UserService

============================================================
✨ 集成示例完成！
============================================================
```

## 🔍 特性说明

### 1. 三模块集成

ApplicationContext 结构体包含了三个核心模块：

```moonbit
pub struct ApplicationContext {
  property_resolver : @PropertyResolver.PropertyResolver  // 配置管理
  resource_resolver : @ResourceResolver.ResourceResolver  // 资源扫描
  beans : @hashmap.HashMap[String, @BeanDefinition.BeanDefinition]  // Bean定义
}
```

### 2. Bean 创建顺序

Bean 按照 `order` 字段排序创建，数值越小越先创建：

```moonbit
ctx.register_bean("dataSource", "...", 10, false)      // 第一个创建
ctx.register_bean("transactionMgr", "...", 20, false)  // 第二个创建
ctx.register_bean("userService", "...", 30, false)     // 第三个创建
```

### 3. @Primary 支持

当有多个相同类型的 Bean 时，标记为 `primary=true` 的将被优先使用：

```moonbit
ctx.register_bean("dataSource1", "DataSource", 10, true)   // Primary
ctx.register_bean("dataSource2", "DataSource", 10, false)  // 普通
```

### 4. Bean 实例管理

每个 BeanDefinition 内部记录是否已创建实例：

```moonbit
match ctx.find_bean("myBean") {
  Some(def) => {
    if def.has_instance() {
      println("Bean 已创建")
    } else {
      println("Bean 未创建")
    }
  }
  None => ()
}
```

## ⚠️ 当前限制

1. **不支持自动扫描** - ResourceResolver 虽然集成，但需要手动调用扫描
2. **不支持依赖注入** - 需要手动管理 Bean 之间的依赖
3. **不支持初始化方法** - init/destroy 方法虽然在 BeanDefinition 中定义，但未实际调用
4. **不支持工厂方法** - 虽然 BeanDefinition 支持，但 ApplicationContext 未实现

## 🔜 下一步计划

1. **自动扫描** - 实现 `scan_and_register()` 方法
2. **依赖注入** - @Autowired、@Value 支持
3. **生命周期** - 实际调用 init/destroy 方法
4. **工厂方法** - 支持 @Bean 注解的工厂方法创建

## 📚 相关文档

- [PropertyResolver 文档](../PropertyResolver/README.md)
- [ResourceResolver 文档](../ResourceResolver/README.md)
- [BeanDefinition 文档](../BeanDefinition/README.md)
- [集成示例](../../../integration-demo/main.mbt)

## 🧪 测试

运行 ApplicationContext 测试：

```bash
moon check autumn-frame/Autumn-Ioc/ApplicationContext
```

所有测试都已通过 ✅

---

**作者**: GitHub Copilot  
**更新时间**: 2025-10-12  
**状态**: ✅ 基本功能完成，真正集成三个模块
