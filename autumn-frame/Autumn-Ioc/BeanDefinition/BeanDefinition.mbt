/// BeanDefinition - Bean 定义
/// 
/// 存储 Bean 的所有定义信息，用于后续创建 Bean 实例、解析依赖、调用初始化方法等
/// 
/// 对应 Java Spring 的 BeanDefinition

/// Bean 的创建方式
pub enum BeanCreationType {
  Constructor // 通过构造函数创建（@Component）
  FactoryMethod(String) // 通过工厂方法创建（@Bean），参数是工厂 Bean 的名称
}

/// Bean 实例的包装（由于 Moonbit 没有 Any 类型）
pub enum BeanInstance {
  None
  Instance(String) // 暂时用 String 表示实例的标识符
}

/// BeanDefinition - Bean 定义
pub struct BeanDefinition {
  // === 基本信息 ===
  name : String // 全局唯一的 Bean 名称
  bean_class : String // Bean 的声明类型（完整类名）
  
  // === 创建信息 ===
  creation_type : BeanCreationType // 创建方式
  factory_method_name : String? // 工厂方法名称（用于 @Bean）
  
  // === 实例 ===
  mut instance : BeanInstance // Bean 的实例（初始为 None）
  
  // === 顺序与优先级 ===
  order : Int // Bean 的顺序（@Order）
  primary : Bool // 是否标识 @Primary
  
  // === 生命周期方法 ===
  init_method_name : String? // init 方法名称
  destroy_method_name : String? // destroy 方法名称
}

/// 创建 BeanDefinition（通过构造函数）
pub fn BeanDefinition::new_from_constructor(
  name : String,
  bean_class : String,
  order : Int,
  primary : Bool,
  init_method : String?,
  destroy_method : String?
) -> BeanDefinition {
  {
    name,
    bean_class,
    creation_type: Constructor,
    factory_method_name: None,
    instance: None,
    order,
    primary,
    init_method_name: init_method,
    destroy_method_name: destroy_method
  }
}

/// 创建 BeanDefinition（通过工厂方法）
pub fn BeanDefinition::new_from_factory(
  name : String,
  bean_class : String,
  factory_bean_name : String,
  factory_method_name : String,
  order : Int,
  primary : Bool,
  init_method : String?,
  destroy_method : String?
) -> BeanDefinition {
  {
    name,
    bean_class,
    creation_type: FactoryMethod(factory_bean_name),
    factory_method_name: Some(factory_method_name),
    instance: None,
    order,
    primary,
    init_method_name: init_method,
    destroy_method_name: destroy_method
  }
}

/// 获取 Bean 名称
pub fn get_name(self : BeanDefinition) -> String {
  self.name
}

/// 获取 Bean 类型
pub fn get_bean_class(self : BeanDefinition) -> String {
  self.bean_class
}

/// 获取实例（返回是否有实例的标识）
pub fn get_instance(self : BeanDefinition) -> BeanInstance {
  self.instance
}

/// 设置实例
pub fn set_instance(self : BeanDefinition, instance_id : String) -> Unit {
  self.instance = Instance(instance_id)
}

/// 是否已创建实例
pub fn has_instance(self : BeanDefinition) -> Bool {
  match self.instance {
    Instance(_) => true
    None => false
  }
}

/// 是否是 Primary
pub fn is_primary(self : BeanDefinition) -> Bool {
  self.primary
}

/// 获取顺序
pub fn get_order(self : BeanDefinition) -> Int {
  self.order
}

/// 是否是通过构造函数创建
pub fn is_constructor_creation(self : BeanDefinition) -> Bool {
  match self.creation_type {
    Constructor => true
    _ => false
  }
}

/// 是否是通过工厂方法创建
pub fn is_factory_creation(self : BeanDefinition) -> Bool {
  match self.creation_type {
    FactoryMethod(_) => true
    _ => false
  }
}

/// 获取工厂 Bean 名称
pub fn get_factory_bean_name(self : BeanDefinition) -> String? {
  match self.creation_type {
    FactoryMethod(name) => Some(name)
    _ => None
  }
}

/// 获取工厂方法名称
pub fn get_factory_method_name(self : BeanDefinition) -> String? {
  self.factory_method_name
}

/// 获取初始化方法名称
pub fn get_init_method_name(self : BeanDefinition) -> String? {
  self.init_method_name
}

/// 获取销毁方法名称
pub fn get_destroy_method_name(self : BeanDefinition) -> String? {
  self.destroy_method_name
}

/// 转换为字符串（用于调试）
pub fn to_string(self : BeanDefinition) -> String {
  let mut s = "BeanDefinition [name=" + self.name
  s = s + ", beanClass=" + self.bean_class
  
  match self.creation_type {
    Constructor => s = s + ", factory=null"
    FactoryMethod(factory_name) => {
      s = s + ", factory=" + factory_name
      match self.factory_method_name {
        Some(method_name) => s = s + "." + method_name + "()"
        None => ()
      }
    }
  }
  
  match self.init_method_name {
    Some(init) => s = s + ", init-method=" + init
    None => s = s + ", init-method=null"
  }
  
  match self.destroy_method_name {
    Some(destroy) => s = s + ", destroy-method=" + destroy
    None => s = s + ", destroy-method=null"
  }
  
  s = s + ", primary=" + self.primary.to_string()
  s = s + ", order=" + self.order.to_string()
  
  match self.instance {
    Instance(_) => s = s + ", instance=<created>"
    None => s = s + ", instance=null"
  }
  
  s + "]"
}

/// 实现 Show trait（用于打印）
pub impl Show for BeanDefinition with output(self, logger) {
  logger.write_string(self.to_string())
}

/// 实现 Compare trait（用于排序，按 order 排序）
pub impl Eq for BeanDefinition with equal(self, other) {
  self.name == other.name && self.bean_class == other.bean_class
}

pub impl Compare for BeanDefinition with compare(self, other) {
  self.order.compare(other.order)
}

// ========== 测试 ==========

test "BeanDefinition 构造函数创建" {
  let def = BeanDefinition::new_from_constructor(
    "myBean",
    "com.example.MyBean",
    0,
    false,
    Some("init"),
    Some("destroy")
  )
  
  if def.get_name() != "myBean" {
    abort("name mismatch")
  }
  
  if def.get_bean_class() != "com.example.MyBean" {
    abort("bean_class mismatch")
  }
  
  if not(def.is_constructor_creation()) {
    abort("should be constructor creation")
  }
  
  if def.has_instance() {
    abort("should not have instance initially")
  }
  
  if def.get_order() != 0 {
    abort("order mismatch")
  }
}

test "BeanDefinition 工厂方法创建" {
  let def = BeanDefinition::new_from_factory(
    "dataSource",
    "javax.sql.DataSource",
    "appConfig",
    "createDataSource",
    1,
    true,
    Some("init"),
    Some("close")
  )
  
  if def.get_name() != "dataSource" {
    abort("name mismatch")
  }
  
  if not(def.is_factory_creation()) {
    abort("should be factory creation")
  }
  
  match def.get_factory_bean_name() {
    Some(name) => if name != "appConfig" {
      abort("factory bean name mismatch")
    }
    None => abort("should have factory bean name")
  }
  
  match def.get_factory_method_name() {
    Some(method_name) => if method_name != "createDataSource" {
      abort("factory method name mismatch")
    }
    None => abort("should have factory method name")
  }
  
  if not(def.is_primary()) {
    abort("should be primary")
  }
}

test "BeanDefinition 实例设置" {
  let def = BeanDefinition::new_from_constructor(
    "testBean",
    "com.example.TestBean",
    0,
    false,
    None,
    None
  )
  
  if def.has_instance() {
    abort("should not have instance initially")
  }
  
  // 设置实例（这里用字符串模拟）
  def.set_instance("instance_object")
  
  if not(def.has_instance()) {
    abort("should have instance after setting")
  }
  
  match def.get_instance() {
    Instance(_) => () // 成功
    None => abort("should return instance")
  }
}

test "BeanDefinition 排序" {
  let def1 = BeanDefinition::new_from_constructor(
    "bean1", "Class1", 10, false, None, None
  )
  let def2 = BeanDefinition::new_from_constructor(
    "bean2", "Class2", 5, false, None, None
  )
  let def3 = BeanDefinition::new_from_constructor(
    "bean3", "Class3", 15, false, None, None
  )
  
  // 测试比较
  if def1.compare(def2) <= 0 {
    abort("def1 should be greater than def2")
  }
  
  if def2.compare(def3) >= 0 {
    abort("def2 should be less than def3")
  }
}

test "BeanDefinition to_string" {
  let def = BeanDefinition::new_from_factory(
    "myDataSource",
    "javax.sql.DataSource",
    "config",
    "createDataSource",
    1,
    true,
    Some("init"),
    Some("close")
  )
  
  let s = def.to_string()
  
  // 检查字符串包含关键信息
  if not(s.contains("myDataSource")) {
    abort("string should contain bean name")
  }
  
  if not(s.contains("DataSource")) {
    abort("string should contain bean class")
  }
  
  if not(s.contains("primary=true")) {
    abort("string should contain primary info")
  }
}
