/// ProxyFactory - 代理工厂
/// 
/// 创建代理对象，拦截方法调用

// ========== 导入依赖 ==========

///|
/// ApplicationContext 引用类型（避免循环依赖）
/// 
/// 注意：这里使用类型别名避免直接依赖 ApplicationContext
/// 实际使用时在 Integration 模块中做类型转换
pub type ApplicationContextRef = @hashmap.HashMap[String, String]

///|
/// 方法拦截器函数类型
/// 
/// 参数：
/// - context: ApplicationContext（使用类型别名避免循环依赖）
/// - bean_name: Bean 名称
/// - method_name: 方法名称
/// - args: 方法参数
/// - proceed: 继续执行原方法的函数
/// 
/// 返回值：
/// - Some(value): 跳过原方法，直接返回该值
/// - None: 继续执行原方法
pub type MethodInterceptor = (
  ApplicationContextRef,
  String,
  String,
  Array[String],
  () -> String?,
) -> String?

// ========== 代理定义 ==========

///|
/// 代理 Bean
pub struct ProxyBean {
  target_bean_name : String
  interceptors : Array[MethodInterceptor]
}

///|
/// 创建代理 Bean
pub fn ProxyBean::new(
  target_bean_name : String,
  interceptors : Array[MethodInterceptor],
) -> ProxyBean {
  { target_bean_name, interceptors }
}

// ========== 代理工厂 ==========

///|
/// 代理工厂
pub struct ProxyFactory {
  // Bean 到拦截器的映射（Bean 名称 -> 拦截器列表）
  bean_interceptors : @hashmap.HashMap[String, Array[MethodInterceptor]]
}

///|
/// 创建代理工厂
pub fn ProxyFactory::new() -> ProxyFactory {
  { bean_interceptors: @hashmap.new() }
}

///|
/// 为 Bean 添加拦截器
pub fn ProxyFactory::add_interceptor(
  self : ProxyFactory,
  bean_name : String,
  interceptor : MethodInterceptor,
) -> Unit {
  match self.bean_interceptors.get(bean_name) {
    Some(existing) => {
      existing.push(interceptor)
      self.bean_interceptors.set(bean_name, existing)
    }
    None => self.bean_interceptors.set(bean_name, [interceptor])
  }
}

///|
/// 创建代理 Bean
pub fn ProxyFactory::create_proxy(
  self : ProxyFactory,
  bean_name : String,
) -> ProxyBean? {
  match self.bean_interceptors.get(bean_name) {
    Some(interceptors) => Some(ProxyBean::new(bean_name, interceptors))
    None => None
  }
}

///|
/// 获取 Bean 的拦截器
pub fn ProxyFactory::get_interceptors(
  self : ProxyFactory,
  bean_name : String,
) -> Array[MethodInterceptor] {
  match self.bean_interceptors.get(bean_name) {
    Some(interceptors) => interceptors
    None => []
  }
}
