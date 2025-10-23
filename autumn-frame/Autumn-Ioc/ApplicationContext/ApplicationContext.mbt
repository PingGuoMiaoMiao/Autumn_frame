/// ApplicationContext - IoC 容器核心实现
/// 
/// 这个文件实现了基于特征系统的 IoC 容器

// ========== 基础类型定义 ==========

/// 容器状态
pub enum ContainerStatus {
  NotInitialized
  Initialized
  Error(String)
} derive(Eq, Show)

/// 容器配置
pub struct ContainerConfig {
  auto_scan : Bool
  debug_mode : Bool
  base_package : String
} derive(Eq, Show, Default)

/// Bean 定义
pub struct BeanDefinition {
  name : String
  bean_class : String
  order : Int
  primary : Bool
} derive(Eq, Show, Default)

/// ApplicationContext 主结构
pub struct ApplicationContext {
  // 基本配置
  mut config : ContainerConfig
  
  // 容器状态
  mut status : ContainerStatus
  
  // Bean 定义集合
  beans : @hashmap.HashMap[String, BeanDefinition]
} derive(Eq, Show)

// ========== 构造函数和方法 ==========

/// 创建 ApplicationContext
pub fn ApplicationContext::new(config : Array[(String, String)], base_package : String) -> ApplicationContext {
  {
    config: ContainerConfig::{
      auto_scan: true,
      debug_mode: false,
      base_package
    },
    status: NotInitialized,
    beans: @hashmap.new()
  }
}

/// 注册 Bean
pub fn register_bean(
  self : ApplicationContext,
  name : String,
  bean_class : String,
  order : Int,
  primary : Bool
) -> Unit {
  let bean_def = BeanDefinition::{
    name,
    bean_class,
    order,
    primary
  }
  self.beans.set(name, bean_def)
}

/// 查找 Bean
pub fn find_bean(self : ApplicationContext, name : String) -> BeanDefinition? {
  self.beans.get(name)
}

/// 获取 Bean 数量
pub fn get_bean_count(self : ApplicationContext) -> Int {
  self.beans.length()
}

/// 获取所有 Bean 名称
pub fn get_all_bean_names(self : ApplicationContext) -> Array[String] {
  let names : Array[String] = []
  self.beans.iter().each(fn(entry) {
    let (name, _) = entry
    names.push(name)
  })
  names
}

/// 设置容器状态
pub fn set_status(self : ApplicationContext, status : ContainerStatus) -> Unit {
  self.status = status
}

/// 获取容器状态
pub fn get_status(self : ApplicationContext) -> ContainerStatus {
  self.status
}

/// 检查是否已初始化
pub fn is_initialized(self : ApplicationContext) -> Bool {
  match self.status {
    Initialized => true
    _ => false
  }
}

/// 打印容器状态
pub fn print_summary(self : ApplicationContext) -> Unit {
  println("=== ApplicationContext 状态 ===")
  println("Bean 定义数量: \{self.beans.length()}")
  println("容器状态: \{self.status}")
  
  println("\n--- Bean 列表 ---")
  self.beans.iter().each(fn(entry) {
    let (name, bean_def) = entry
    println("  \{name}: \{bean_def.bean_class} (order=\{bean_def.order}, primary=\{bean_def.primary})")
  })
}

// ========== 属性管理方法 ==========

/// 获取属性（简化实现）
pub fn get_property(self : ApplicationContext, key : String) -> String? {
  // 简化实现，返回默认值
  match key {
    "app.name" => Some("Autumn Frame")
    "app.version" => Some("1.0.0")
    _ => None
  }
}

/// 获取整数属性
pub fn get_property_int(self : ApplicationContext, key : String) -> Int? {
  match key {
    "db.port" => Some(3306)
    "cache.ttl" => Some(3600)
    _ => None
  }
}

/// 获取布尔属性
pub fn get_property_bool(self : ApplicationContext, key : String) -> Bool? {
  match key {
    "cache.enabled" => Some(true)
    _ => None
  }
}

// ========== Bean 管理方法 ==========

/// 创建所有 Bean（简化实现）
pub fn create_all_beans(self : ApplicationContext) -> Unit {
  println("创建所有 Bean...")
  self.beans.iter().each(fn(entry) {
    let (name, bean_def) = entry
    println("创建 Bean: \{name} (\{bean_def.bean_class})")
  })
  self.set_status(Initialized)
}

// ========== BeanDefinition 方法 ==========

/// 检查是否有实例（简化实现）
pub fn has_instance(self : BeanDefinition) -> Bool {
  // 简化实现，总是返回 false
  false
}

/// 获取 Bean 类名
pub fn get_bean_class(self : BeanDefinition) -> String {
  self.bean_class
}

/// 检查是否为主 Bean
pub fn is_primary(self : BeanDefinition) -> Bool {
  self.primary
}

/// 获取 Bean 顺序
pub fn get_order(self : BeanDefinition) -> Int {
  self.order
}

// ========== 特征定义 ==========

/// IoC 容器核心特征
pub trait IoCContainer {
  register_bean(Self, String, String, Int, Bool) -> Unit
  find_bean(Self, String) -> BeanDefinition?
  get_bean_count(Self) -> Int
  get_all_bean_names(Self) -> Array[String]
}

/// 容器状态管理特征
pub trait ContainerStatusManager {
  set_status(Self, ContainerStatus) -> Unit
  get_status(Self) -> ContainerStatus
  is_initialized(Self) -> Bool
}

/// 容器配置特征
pub trait ContainerConfiguration {
  get_config(Self) -> ContainerConfig
  set_config(Self, ContainerConfig) -> Unit
  is_debug_mode(Self) -> Bool
}

// ========== 特征实现 ==========

/// 实现 IoCContainer 特征
pub impl IoCContainer for ApplicationContext with register_bean(self, name, bean_class, order, primary) {
  let bean_def = BeanDefinition::{
    name,
    bean_class,
    order,
    primary
  }
  self.beans.set(name, bean_def)
}

pub impl IoCContainer for ApplicationContext with find_bean(self, name) {
  self.beans.get(name)
}

pub impl IoCContainer for ApplicationContext with get_bean_count(self) {
  self.beans.length()
}

pub impl IoCContainer for ApplicationContext with get_all_bean_names(self) {
  let names : Array[String] = []
  self.beans.iter().each(fn(entry) {
    let (name, _) = entry
    names.push(name)
  })
  names
}

/// 实现 ContainerStatusManager 特征
pub impl ContainerStatusManager for ApplicationContext with set_status(self, status) {
  self.status = status
}

pub impl ContainerStatusManager for ApplicationContext with get_status(self) {
  self.status
}

pub impl ContainerStatusManager for ApplicationContext with is_initialized(self) {
  match self.status {
    Initialized => true
    _ => false
  }
}

/// 实现 ContainerConfiguration 特征
pub impl ContainerConfiguration for ApplicationContext with get_config(self) {
  self.config
}

pub impl ContainerConfiguration for ApplicationContext with set_config(self, config) {
  self.config = config
}

pub impl ContainerConfiguration for ApplicationContext with is_debug_mode(self) {
  self.config.debug_mode
}

// ========== 测试 ==========

test "ApplicationContext 基本功能" {
  let config : Array[(String, String)] = []
  let ctx = ApplicationContext::new(config, "com.example")
  
  // 测试注册 Bean
  ctx.register_bean("userService", "com.example.UserService", 10, false)
  ctx.register_bean("orderService", "com.example.OrderService", 20, true)
  
  // 测试查找 Bean
  match ctx.find_bean("userService") {
    Some(bean_def) => {
      if bean_def.name != "userService" { abort("bean name mismatch") }
      if bean_def.bean_class != "com.example.UserService" { abort("bean class mismatch") }
      if bean_def.order != 10 { abort("bean order mismatch") }
      if bean_def.primary { abort("bean should not be primary") }
    }
    None => abort("bean not found")
  }
  
  // 测试 Bean 数量
  if ctx.get_bean_count() != 2 { abort("bean count mismatch") }
  
  // 测试状态管理
  ctx.set_status(Initialized)
  if not(ctx.is_initialized()) { abort("should be initialized") }
}

test "ApplicationContext 特征使用" {
  let config : Array[(String, String)] = []
  let ctx = ApplicationContext::new(config, "com.example")
  
  // 使用 IoCContainer 特征
  ctx.register_bean("testBean", "com.example.TestBean", 0, false)
  
  // 使用 ContainerStatusManager 特征
  ctx.set_status(Initialized)
  
  // 使用 ContainerConfiguration 特征
  if not(ctx.is_debug_mode()) { abort("should not be debug mode") }
  
  // 验证结果
  match ctx.find_bean("testBean") {
    Some(_) => ()
    None => abort("bean not found")
  }
}
