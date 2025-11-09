/// FunctionalProxy - 函数式代理
/// 
/// 不使用类代理，而是使用函数包装器实现 AOP
/// 
/// 优点：
/// - ✅ 不需要动态生成类
/// - ✅ 适用于函数式编程风格
/// - ✅ 性能好（编译时确定）
/// 
/// 缺点：
/// - ❌ 不能代理结构体的方法
/// - ❌ 需要手动包装每个函数

// ========== 函数式代理实现 ==========

///|
/// 函数拦截器
pub type FunctionInterceptor = (String, Array[String]) -> Unit // (function_name, args)

///|
/// 函数代理包装器
/// 
/// 注意：由于包含函数类型，无法 derive Eq 和 Show
pub struct FunctionalProxy {
  before_interceptors : Array[FunctionInterceptor]
  after_interceptors : Array[FunctionInterceptor]
}

///|
/// 创建函数代理
pub fn FunctionalProxy::new() -> FunctionalProxy {
  { before_interceptors: [], after_interceptors: [] }
}

///|
/// 添加 Before 拦截器
pub fn FunctionalProxy::add_before(
  self : FunctionalProxy,
  interceptor : FunctionInterceptor,
) -> FunctionalProxy {
  let new_interceptors = self.before_interceptors
  new_interceptors.push(interceptor)
  {
    before_interceptors: new_interceptors,
    after_interceptors: self.after_interceptors,
  }
}

///|
/// 添加 After 拦截器
pub fn FunctionalProxy::add_after(
  self : FunctionalProxy,
  interceptor : FunctionInterceptor,
) -> FunctionalProxy {
  let new_interceptors = self.after_interceptors
  new_interceptors.push(interceptor)
  {
    before_interceptors: self.before_interceptors,
    after_interceptors: new_interceptors,
  }
}

///|
/// 包装无参数无返回值的函数
pub fn FunctionalProxy::wrap_unit(
  self : FunctionalProxy,
  original_fn : () -> Unit,
  function_name : String,
) -> () -> Unit {
  fn() -> Unit {
    // Before Advice
    let _ = self.before_interceptors.map(fn(interceptor) {
      interceptor(function_name, [])
    })

    // 调用原始函数
    original_fn()

    // After Advice
    let _ = self.after_interceptors.map(fn(interceptor) {
      interceptor(function_name, [])
    })

  }
}

///|
/// 包装有返回值的函数
pub fn[T] FunctionalProxy::wrap(
  self : FunctionalProxy,
  original_fn : () -> T,
  function_name : String,
) -> () -> T {
  fn() -> T {
    // Before Advice
    let _ = self.before_interceptors.map(fn(interceptor) {
      interceptor(function_name, [])
    })

    // 调用原始函数
    let result = original_fn()

    // After Advice
    let _ = self.after_interceptors.map(fn(interceptor) {
      interceptor(function_name, [])
    })
    result
  }
}

///|
/// 包装有参数的函数
/// 
/// 注意：需要参数类型实现 Show trait（用于日志）
pub fn[T] FunctionalProxy::wrap_args(
  self : FunctionalProxy,
  original_fn : (T) -> Unit,
  function_name : String,
  args_to_string : (T) -> String,
) -> (T) -> Unit {
  fn(args : T) -> Unit {
    // Before Advice
    let _ = self.before_interceptors.map(fn(interceptor) {
      interceptor(function_name, [args_to_string(args)])
    })

    // 调用原始函数
    original_fn(args)

    // After Advice
    let _ = self.after_interceptors.map(fn(interceptor) {
      interceptor(function_name, [args_to_string(args)])
    })

  }
}

///|
/// 包装完整函数（参数 + 返回值）
/// 
/// 注意：由于类型限制，此函数需要参数和返回值都实现 Show trait
pub fn[Args, Ret] FunctionalProxy::wrap_full(
  self : FunctionalProxy,
  original_fn : (Args) -> Ret,
  function_name : String,
  args_to_string : (Args) -> String,
) -> (Args) -> Ret {
  fn(args : Args) -> Ret {
    // Before Advice
    let _ = self.before_interceptors.map(fn(interceptor) {
      interceptor(function_name, [args_to_string(args)])
    })

    // 调用原始函数
    let result = original_fn(args)

    // After Advice
    let _ = self.after_interceptors.map(fn(interceptor) {
      interceptor(function_name, [args_to_string(args)])
    })
    result
  }
}

///|
/// 使用示例
pub fn example_usage() -> Unit {
  // 原始函数
  let original_fn = fn(x : Int) -> Int { x * 2 }

  // 创建代理
  let proxy1 = FunctionalProxy::new()
  let proxy2 = proxy1.add_before(fn(func_name, args) {
    println("  🔵 [代理] Before \{func_name}, args=\{args}")
  })
  let proxy3 = proxy2.add_after(fn(func_name, args) {
    println("  ✅ [代理] After \{func_name}, args=\{args}")
  })

  // 包装函数（需要提供参数转字符串的函数）
  let proxied_fn = proxy3.wrap_full(original_fn, "multiply_by_two", fn(
    x : Int,
  ) -> String {
    x.to_string()
  })

  // 调用代理函数
  let result = proxied_fn(5)
  println("  📊 [代理] 结果: \{result}")
}
