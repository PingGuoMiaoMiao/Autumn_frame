/// ApplicationContext - 简化版 IoC 容器示例
/// 
/// 这个文件展示如何集成使用 ResourceResolver、PropertyResolver 和 BeanDefinition

/// ApplicationContext - IoC 容器
pub struct ApplicationContext {
  // 配置解析器
  property_resolver : @PropertyResolver.PropertyResolver
  
  // 资源解析器
  resource_resolver : @ResourceResolver.ResourceResolver
  
  // Bean 定义集合
  beans : @hashmap.HashMap[String, @BeanDefinition.BeanDefinition]
}

/// 创建 ApplicationContext
pub fn ApplicationContext::new(
  config_properties : Array[(String, String)],
  base_package : String
) -> ApplicationContext {
  // 1. 创建 PropertyResolver
  let property_resolver = @PropertyResolver.PropertyResolver::from_array(config_properties)
  
  // 2. 创建 ResourceResolver
  let resource_resolver = @ResourceResolver.ResourceResolver::new(base_package)
  
  // 3. 创建 Bean 集合
  let beans = @hashmap.new()
  
  { property_resolver, resource_resolver, beans }
}

/// 手动注册 Bean
pub fn register_bean(
  self : ApplicationContext,
  name : String,
  bean_class : String,
  order : Int,
  primary : Bool
) -> Unit {
  let bean_def = @BeanDefinition.BeanDefinition::new_from_constructor(
    name,
    bean_class,
    order,
    primary,
    None,
    None
  )
  self.beans.set(name, bean_def)
}

/// 查找 Bean 定义
pub fn find_bean(self : ApplicationContext, name : String) -> @BeanDefinition.BeanDefinition? {
  self.beans.get(name)
}

/// 获取配置
pub fn get_property(self : ApplicationContext, key : String) -> String? {
  self.property_resolver.get_property(key)
}

/// 获取 Int 配置
pub fn get_property_int(self : ApplicationContext, key : String) -> Int? {
  self.property_resolver.get_property_int(key)
}

/// 获取 Bool 配置
pub fn get_property_bool(self : ApplicationContext, key : String) -> Bool? {
  self.property_resolver.get_property_bool(key)
}

/// 创建 Bean 实例
pub fn create_bean(self : ApplicationContext, name : String) -> Bool {
  match self.beans.get(name) {
    Some(bean_def) => {
      if bean_def.has_instance() {
        println("Bean '\{name}' 已存在")
        return true
      }
      
      let instance_id = "instance_of_\{name}"
      bean_def.set_instance(instance_id)
      
      println("创建 Bean: \{name} (\{bean_def.get_bean_class()})")
      true
    }
    None => {
      println("错误：找不到 Bean '\{name}'")
      false
    }
  }
}

/// 创建所有 Bean
pub fn create_all_beans(self : ApplicationContext) -> Unit {
  // 收集所有 Bean
  let defs : Array[@BeanDefinition.BeanDefinition] = []
  self.beans.iter().each(fn(entry) {
    let (_, def) = entry
    defs.push(def)
  })
  
  // 按 order 排序（冒泡排序）
  for i = 0; i < defs.length(); i = i + 1 {
    for j = 0; j < defs.length() - 1 - i; j = j + 1 {
      if defs[j].get_order() > defs[j + 1].get_order() {
        let temp = defs[j]
        defs[j] = defs[j + 1]
        defs[j + 1] = temp
      }
    }
  }
  
  // 依次创建
  for i = 0; i < defs.length(); i = i + 1 {
    ignore(self.create_bean(defs[i].get_name()))
  }
}

/// 打印容器状态
pub fn print_summary(self : ApplicationContext) -> Unit {
  println("=== ApplicationContext 状态 ===")
  
  // 统计实例数量
  let mut instance_count = 0
  self.beans.iter().each(fn(entry) {
    let (_, def) = entry
    if def.has_instance() {
      instance_count = instance_count + 1
    }
  })
  
  println("Bean 定义数量: \{self.beans.size()}")
  println("已创建实例: \{instance_count}")
  
  println("\n--- Bean 列表 ---")
  self.beans.iter().each(fn(entry) {
    let (name, def) = entry
    let status = if def.has_instance() { "已创建" } else { "未创建" }
    println("  \{name}: \{def.get_bean_class()} [\{status}]")
  })
  
  println("\n--- 配置属性示例 ---")
  match self.get_property("app.name") {
    Some(v) => println("  app.name = \{v}")
    None => ()
  }
  match self.get_property("app.version") {
    Some(v) => println("  app.version = \{v}")
    None => ()
  }
}

// ========== 测试 ==========

test "ApplicationContext 基本功能" {
  let config = [
    ("app.name", "TestApp"),
    ("app.version", "1.0.0"),
    ("db.port", "3306")
  ]
  
  let ctx = ApplicationContext::new(config, "com.example")
  
  // 测试配置
  match ctx.get_property("app.name") {
    Some(name) => if name != "TestApp" { abort("app.name error") }
    None => abort("app.name not found")
  }
  
  match ctx.get_property_int("db.port") {
    Some(port) => if port != 3306 { abort("db.port error") }
    None => abort("db.port not found")
  }
}

test "ApplicationContext 注册和创建 Bean" {
  let config = [("app.name", "TestApp")]
  let ctx = ApplicationContext::new(config, "")
  
  // 注册 Bean
  ctx.register_bean("userService", "com.example.UserService", 1, false)
  ctx.register_bean("orderService", "com.example.OrderService", 2, false)
  
  // 检查 Bean
  match ctx.find_bean("userService") {
    Some(def) => {
      if def.get_name() != "userService" { abort("name mismatch") }
    }
    None => abort("Bean not found")
  }
  
  // 创建 Bean
  let success = ctx.create_bean("userService")
  if not(success) { abort("create failed") }
  
  // 检查是否已创建
  match ctx.find_bean("userService") {
    Some(def) => {
      if not(def.has_instance()) { abort("should have instance") }
    }
    None => abort("Bean not found")
  }
}

test "ApplicationContext 创建所有 Bean" {
  let config = [("app.name", "TestApp")]
  let ctx = ApplicationContext::new(config, "")
  
  // 注册多个 Bean（不同顺序）
  ctx.register_bean("bean3", "Class3", 30, false)
  ctx.register_bean("bean1", "Class1", 10, false)
  ctx.register_bean("bean2", "Class2", 20, false)
  
  // 创建所有
  ctx.create_all_beans()
  
  // 验证都已创建
  match ctx.find_bean("bean1") {
    Some(def) => if not(def.has_instance()) { abort("bean1 not created") }
    None => abort("bean1 not found")
  }
  
  match ctx.find_bean("bean2") {
    Some(def) => if not(def.has_instance()) { abort("bean2 not created") }
    None => abort("bean2 not found")
  }
  
  match ctx.find_bean("bean3") {
    Some(def) => if not(def.has_instance()) { abort("bean3 not created") }
    None => abort("bean3 not found")
  }
}
