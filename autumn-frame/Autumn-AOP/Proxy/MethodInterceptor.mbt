/// MethodInterceptor - 方法拦截器
/// 
/// 实现方法调用拦截逻辑
/// 
/// 注意：MethodInterceptor 类型已在 ProxyFactory.mbt 中定义
/// 这里使用相同包内的类型，所以可以直接使用 MethodInterceptor

///|
/// 方法调用上下文
/// 
/// 注意：为避免循环依赖，context 使用 HashMap 代替 ApplicationContext
pub struct MethodInvocation {
  context : @hashmap.HashMap[String, String] // 使用 HashMap 避免循环依赖
  bean_name : String
  method_name : String
  args : Array[String]
  interceptors : Array[MethodInterceptor] // 直接使用同包中定义的 MethodInterceptor
  current_index : Int
}

///|
/// 创建方法调用上下文
pub fn MethodInvocation::new(
  context : @hashmap.HashMap[String, String],
  bean_name : String,
  method_name : String,
  args : Array[String],
  interceptors : Array[MethodInterceptor],
) -> MethodInvocation {
  { context, bean_name, method_name, args, interceptors, current_index: 0 }
}

///|
/// 执行调用链
pub fn MethodInvocation::proceed(self : MethodInvocation) -> String? {
  // 如果还有拦截器，执行下一个拦截器
  if self.current_index < self.interceptors.length() {
    let interceptor = self.interceptors[self.current_index]
    let next_index = self.current_index + 1

    // 创建 proceed 函数（递归调用）
    let proceed_fn = fn() -> String? {
      let next_invocation = MethodInvocation::{
        context: self.context,
        bean_name: self.bean_name,
        method_name: self.method_name,
        args: self.args,
        interceptors: self.interceptors,
        current_index: next_index,
      }
      next_invocation.proceed()
    }

    // 调用拦截器
    interceptor(
      self.context,
      self.bean_name,
      self.method_name,
      self.args,
      proceed_fn,
    )
  } else {
    // 没有更多拦截器，返回 None 表示执行原方法
    None
  }
}
