/// 集成示例 - 展示 ResourceResolver、PropertyResolver、BeanDefinition 和 ApplicationContext 的使用
/// 
/// 这是一个完整的示例，展示如何使用 Autumn IoC 容器

fn main {
  println("=".repeat(60))
  println("Autumn IoC 容器集成示例")
  println("=".repeat(60))
  println("")
  
  // ========== 第一部分：创建配置 ==========
  println("📝 第一步：准备配置属性")
  println("─".repeat(60))
  
  let config = [
    ("app.name", "MyApplication"),
    ("app.version", "1.0.0"),
    ("app.author", "Autumn Framework"),
    ("db.host", "localhost"),
    ("db.port", "3306"),
    ("db.username", "root"),
    ("db.password", "password"),
    ("db.database", "mydb"),
    ("cache.enabled", "true"),
    ("cache.ttl", "600")
  ]
  
  println("✓ 准备了 \{config.length()} 个配置项")
  println("")
  
  // ========== 第二部分：创建 IoC 容器 ==========
  println("🏗️  第二步：创建 ApplicationContext")
  println("─".repeat(60))
  
  let ctx = @ApplicationContext.ApplicationContext::new(config, "com.example")
  
  println("✓ ApplicationContext 创建成功")
  println("  - PropertyResolver: 已加载")
  println("  - ResourceResolver: 已加载")
  println("  - Bean 容器: 已初始化")
  println("")
  
  // ========== 第三部分：演示 PropertyResolver 功能 ==========
  println("⚙️  第三步：测试 PropertyResolver 功能")
  println("─".repeat(60))
  
  // 获取字符串配置
  match ctx.get_property("app.name") {
    Some(name) => println("✓ app.name = \{name}")
    None => println("✗ app.name 未找到")
  }
  
  match ctx.get_property("app.version") {
    Some(version) => println("✓ app.version = \{version}")
    None => println("✗ app.version 未找到")
  }
  
  // 获取 Int 配置
  match ctx.get_property_int("db.port") {
    Some(port) => println("✓ db.port = \{port} (Int)")
    None => println("✗ db.port 未找到或格式错误")
  }
  
  match ctx.get_property_int("cache.ttl") {
    Some(ttl) => println("✓ cache.ttl = \{ttl} 秒 (Int)")
    None => println("✗ cache.ttl 未找到或格式错误")
  }
  
  // 获取 Bool 配置
  match ctx.get_property_bool("cache.enabled") {
    Some(enabled) => println("✓ cache.enabled = \{enabled} (Bool)")
    None => println("✗ cache.enabled 未找到或格式错误")
  }
  
  println("")
  
  // ========== 第四部分：注册 Bean 定义 ==========
  println("📦 第四步：注册 Bean 定义")
  println("─".repeat(60))
  
  // 注册数据库相关 Bean
  ctx.register_bean(
    "dataSource",
    "com.example.db.DataSource",
    10,  // order: 先创建
    true  // primary
  )
  println("✓ 注册 Bean: dataSource (order=10, primary=true)")
  
  ctx.register_bean(
    "transactionManager",
    "com.example.db.TransactionManager",
    20,  // order: 依赖 dataSource
    false
  )
  println("✓ 注册 Bean: transactionManager (order=20)")
  
  // 注册服务层 Bean
  ctx.register_bean(
    "userService",
    "com.example.service.UserService",
    30,
    false
  )
  println("✓ 注册 Bean: userService (order=30)")
  
  ctx.register_bean(
    "orderService",
    "com.example.service.OrderService",
    30,
    false
  )
  println("✓ 注册 Bean: orderService (order=30)")
  
  // 注册控制器 Bean
  ctx.register_bean(
    "userController",
    "com.example.controller.UserController",
    40,
    false
  )
  println("✓ 注册 Bean: userController (order=40)")
  
  println("")
  
  // ========== 第五部分：创建 Bean 实例 ==========
  println("🔨 第五步：创建 Bean 实例（按顺序）")
  println("─".repeat(60))
  
  ctx.create_all_beans()
  
  println("")
  
  // ========== 第六部分：查看容器状态 ==========
  println("📊 第六步：查看容器状态")
  println("─".repeat(60))
  
  ctx.print_summary()
  
  println("")
  
  // ========== 第七部分：验证 Bean 创建 ==========
  println("✅ 第七步：验证 Bean 是否正确创建")
  println("─".repeat(60))
  
  match ctx.find_bean("dataSource") {
    Some(def) => {
      if def.has_instance() {
        println("✓ dataSource: 已创建实例")
        println("  - 类型: \{def.get_bean_class()}")
        println("  - Primary: \{def.is_primary()}")
        println("  - Order: \{def.get_order()}")
      } else {
        println("✗ dataSource: 未创建实例")
      }
    }
    None => println("✗ dataSource: Bean 定义不存在")
  }
  
  println("")
  
  match ctx.find_bean("userService") {
    Some(def) => {
      if def.has_instance() {
        println("✓ userService: 已创建实例")
        println("  - 类型: \{def.get_bean_class()}")
      } else {
        println("✗ userService: 未创建实例")
      }
    }
    None => println("✗ userService: Bean 定义不存在")
  }
  
  println("")
  
  // ========== 总结 ==========
  println("=".repeat(60))
  println("✨ 集成示例完成！")
  println("=".repeat(60))
  println("")
  println("本示例展示了：")
  println("  1. ✅ PropertyResolver - 配置管理（String/Int/Bool）")
  println("  2. ✅ BeanDefinition - Bean 定义（order、primary）")
  println("  3. ✅ ApplicationContext - IoC 容器集成")
  println("  4. ✅ Bean 生命周期 - 按顺序创建")
  println("")
  println("下一步可以实现：")
  println("  • ResourceResolver 的实际使用（扫描类文件）")
  println("  • 依赖注入（@Autowired）")
  println("  • 初始化和销毁方法调用")
  println("  • 工厂方法创建 Bean")
  println("")
}
