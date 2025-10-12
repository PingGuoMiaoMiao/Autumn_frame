# BeanDefinition - Bean 定义

## 概述

BeanDefinition 是 IoC 容器的核心数据结构，用于存储 Bean 的所有定义信息。它与 ResourceResolver 和 PropertyResolver 配合，共同实现 Spring 风格的依赖注入容器。

## 架构关系

```
ResourceResolver (扫描类)
        ↓
BeanDefinition (Bean 定义)  ← PropertyResolver (配置注入)
        ↓
IoC Container (Bean 容器)
```

### 1. ResourceResolver 的作用
- 扫描指定包下的所有 `.mbt` 文件
- 查找带有 `@Component` 注解的类
- 查找带有 `@Configuration` 和 `@Bean` 的工厂方法

### 2. PropertyResolver 的作用
- 存储配置项（key-value）
- 支持 `${...}` 表达式解析
- 提供配置注入功能（用于 `@Value` 注解）

### 3. BeanDefinition 的作用
- 存储 Bean 的元数据（名称、类型、创建方式等）
- 记录 Bean 的生命周期方法（init、destroy）
- 管理 Bean 的实例
- 支持 Bean 的排序和优先级

## 数据结构

### BeanCreationType - Bean 创建方式

```moonbit
pub enum BeanCreationType {
  Constructor              // 通过构造函数创建（@Component）
  FactoryMethod(String)    // 通过工厂方法创建（@Bean）
}
```

### BeanInstance - Bean 实例包装

```moonbit
pub enum BeanInstance {
  None                     // 未创建
  Instance(String)         // 已创建（存储实例标识符）
}
```

### BeanDefinition 结构

```moonbit
pub struct BeanDefinition {
  name : String                      // Bean 名称（全局唯一）
  bean_class : String                // Bean 声明类型
  creation_type : BeanCreationType   // 创建方式
  factory_method_name : String?      // 工厂方法名称
  mut instance : BeanInstance        // Bean 实例
  order : Int                        // 排序顺序
  primary : Bool                     // 是否为主要 Bean
  init_method_name : String?         // 初始化方法
  destroy_method_name : String?      // 销毁方法
}
```

## 使用示例

### 示例 1: 通过构造函数创建 Bean（@Component）

```moonbit
// 模拟 @Component 注解的类
// @Component
// class UserService { ... }

let bean_def = BeanDefinition::new_from_constructor(
  "userService",                    // Bean 名称
  "com.example.UserService",        // Bean 类型
  0,                                // 默认顺序
  false,                            // 不是 primary
  Some("init"),                     // 初始化方法
  Some("destroy")                   // 销毁方法
)

// 打印 Bean 定义
println(bean_def.to_string())
// 输出: BeanDefinition [name=userService, beanClass=com.example.UserService, 
//        factory=null, init-method=init, destroy-method=destroy, 
//        primary=false, order=0, instance=null]
```

### 示例 2: 通过工厂方法创建 Bean（@Bean）

```moonbit
// 模拟 @Configuration 和 @Bean
// @Configuration
// class AppConfig {
//   @Bean(initMethod="init", destroyMethod="close")
//   DataSource createDataSource() { ... }
// }

let bean_def = BeanDefinition::new_from_factory(
  "dataSource",                     // Bean 名称
  "javax.sql.DataSource",           // Bean 声明类型
  "appConfig",                      // 工厂 Bean 名称
  "createDataSource",               // 工厂方法名称
  1,                                // 顺序
  true,                             // 是 primary
  Some("init"),                     // 初始化方法
  Some("close")                     // 销毁方法
)

println(bean_def.to_string())
// 输出: BeanDefinition [name=dataSource, beanClass=javax.sql.DataSource, 
//        factory=appConfig.createDataSource(), init-method=init, 
//        destroy-method=close, primary=true, order=1, instance=null]
```

### 示例 3: 完整的 IoC 容器流程

```moonbit
// ========== 步骤 1: 使用 ResourceResolver 扫描类 ==========
let resolver = ResourceResolver::new("com.example")
let class_names = resolver.scan(fn(res) {
  if res.name.has_suffix(".mbt") {
    Some(res.name[0:res.name.length() - 4].to_string())
  } else {
    None
  }
})

// ========== 步骤 2: 创建 BeanDefinition ==========
let bean_defs = @hashmap.new()

// 为每个扫描到的类创建 BeanDefinition
let _ = class_names.map(fn(class_name) {
  // 检查是否有 @Component 注解（这里简化处理）
  let bean_name = extract_bean_name(class_name)
  
  let def = BeanDefinition::new_from_constructor(
    bean_name,
    class_name,
    0,
    false,
    None,
    None
  )
  
  bean_defs.set(bean_name, def)
})

// ========== 步骤 3: 使用 PropertyResolver 注入配置 ==========
let properties = PropertyResolver::from_array([
  ("db.host", "localhost"),
  ("db.port", "5432"),
  ("app.name", "MyApp")
])

// 配置可以在创建 Bean 实例时使用
match properties.get_property("db.host") {
  Some(host) => println("Database host: " + host)
  None => ()
}

// ========== 步骤 4: 创建 Bean 实例 ==========
// 遍历所有 BeanDefinition，创建实例
bean_defs.iter().each(fn(entry) {
  let (name, def) = entry
  
  // 模拟创建实例
  def.set_instance(name + "_instance")
  
  println("Created bean: " + def.to_string())
})
```

## API 参考

### 创建 BeanDefinition

```moonbit
// 通过构造函数创建
pub fn BeanDefinition::new_from_constructor(
  name : String,
  bean_class : String,
  order : Int,
  primary : Bool,
  init_method : String?,
  destroy_method : String?
) -> BeanDefinition

// 通过工厂方法创建
pub fn BeanDefinition::new_from_factory(
  name : String,
  bean_class : String,
  factory_bean_name : String,
  factory_method_name : String,
  order : Int,
  primary : Bool,
  init_method : String?,
  destroy_method : String?
) -> BeanDefinition
```

### 查询方法

```moonbit
pub fn get_name(self : BeanDefinition) -> String
pub fn get_bean_class(self : BeanDefinition) -> String
pub fn get_instance(self : BeanDefinition) -> BeanInstance
pub fn get_order(self : BeanDefinition) -> Int
pub fn is_primary(self : BeanDefinition) -> Bool
pub fn has_instance(self : BeanDefinition) -> Bool
pub fn is_constructor_creation(self : BeanDefinition) -> Bool
pub fn is_factory_creation(self : BeanDefinition) -> Bool
pub fn get_factory_bean_name(self : BeanDefinition) -> String?
pub fn get_factory_method_name(self : BeanDefinition) -> String?
pub fn get_init_method_name(self : BeanDefinition) -> String?
pub fn get_destroy_method_name(self : BeanDefinition) -> String?
```

### 修改方法

```moonbit
pub fn set_instance(self : BeanDefinition, instance_id : String) -> Unit
```

### 工具方法

```moonbit
pub fn to_string(self : BeanDefinition) -> String
```

## IoC 容器中的使用

### 1. 按名称查找 Bean

```moonbit
// IoC 容器结构
struct ApplicationContext {
  beans : @hashmap.HashMap[String, BeanDefinition]
}

fn find_bean_definition(ctx : ApplicationContext, name : String) -> BeanDefinition? {
  ctx.beans.get(name)
}

// 使用
match find_bean_definition(context, "userService") {
  Some(def) => println("Found: " + def.to_string())
  None => println("Bean not found")
}
```

### 2. 按类型查找 Bean

```moonbit
fn find_bean_definitions_by_type(
  ctx : ApplicationContext, 
  type_name : String
) -> Array[BeanDefinition] {
  let results = []
  
  ctx.beans.iter().each(fn(entry) {
    let (_, def) = entry
    if def.get_bean_class() == type_name {
      results.push(def)
    }
  })
  
  results
}

// 使用
let defs = find_bean_definitions_by_type(context, "javax.sql.DataSource")
if defs.length() == 0 {
  println("No beans of type DataSource found")
} else if defs.length() == 1 {
  println("Found one bean: " + defs[0].get_name())
} else {
  // 多个 Bean，查找 @Primary
  let mut primary_bean : BeanDefinition? = None
  for i = 0; i < defs.length(); i = i + 1 {
    if defs[i].is_primary() {
      primary_bean = Some(defs[i])
      break
    }
  }
  
  match primary_bean {
    Some(bean) => println("Found primary bean: " + bean.get_name())
    None => println("Multiple beans found but no @Primary")
  }
}
```

### 3. Bean 排序

```moonbit
// BeanDefinition 实现了 Compare trait
let defs = [def1, def2, def3]

// 按 order 排序
defs.sort()

// 输出排序后的 Bean
for i = 0; i < defs.length(); i = i + 1 {
  println(defs[i].get_order().to_string() + ": " + defs[i].get_name())
}
```

## 与 Spring 的对比

| 特性 | Spring BeanDefinition | Moonbit BeanDefinition |
|------|----------------------|------------------------|
| Bean 名称 | ✅ 支持多个别名 | ✅ 单一名称（简化） |
| Bean 类型 | ✅ Class<?> | ✅ String（类名） |
| 创建方式 | ✅ 构造函数/工厂方法 | ✅ 枚举表示 |
| 实例存储 | ✅ Object | ✅ BeanInstance（包装类型） |
| @Primary | ✅ | ✅ |
| @Order | ✅ | ✅ |
| init/destroy | ✅ | ✅ |
| Scope | ✅ singleton/prototype | ❌ 暂不支持 |
| Lazy init | ✅ | ❌ 暂不支持 |
| DependsOn | ✅ | ❌ 暂不支持 |

## 注意事项

1. **Bean 声明类型 vs 实际类型**
   - `bean_class` 存储的是声明类型
   - 实际类型可以是子类（例如 DataSource → HikariDataSource）
   - 这对于类型查找很重要

2. **工厂方法的特殊性**
   - 工厂 Bean 本身也需要创建 BeanDefinition
   - 工厂方法产生的 Bean 需要记录工厂 Bean 的名称

3. **@Primary 的使用**
   - 当按类型查找到多个 Bean 时，返回标记为 @Primary 的那个
   - 如果没有 @Primary 或有多个 @Primary，应该报错

4. **实例管理**
   - `instance` 字段初始为 `None`
   - IoC 容器创建实例后调用 `set_instance()` 设置

## 下一步

完成 BeanDefinition 后，下一步是：

1. **创建 Bean 实例** - 根据 BeanDefinition 创建真正的 Bean
2. **依赖注入** - 解析并注入 Bean 之间的依赖
3. **生命周期管理** - 调用 init 和 destroy 方法
4. **完整的 IoC 容器** - 实现 ApplicationContext

## 相关模块

- [ResourceResolver](../ResourceResolver/README.md) - 类扫描
- [PropertyResolver](../PropertyResolver/README.md) - 配置管理
- [IoC Container](../IoC-Container/README.md) - 完整容器（待实现）

## 测试

运行测试：

```bash
moon check autumn-frame/Autumn-Ioc/BeanDefinition
```

测试覆盖：
- ✅ 构造函数创建
- ✅ 工厂方法创建
- ✅ 实例管理
- ✅ 排序比较
- ✅ 字符串输出

## 作者

GitHub Copilot

## 许可证

Apache-2.0
