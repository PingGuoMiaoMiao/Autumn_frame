/// AopIntegration - AOP 集成模块
/// 
/// 将 AOP 功能集成到 IoC 容器中
/// 
/// 注意：为避免循环依赖，此模块不直接依赖 ApplicationContext
/// 实际使用时，需要在应用层传入 ApplicationContext 实例

// ========== 导入依赖 ==========

///|
/// AOP 集成器
/// 
/// 将切面功能集成到 IoC 容器中
pub struct AopIntegration {
  aspect_registry : @AspectRegistry.AspectRegistry
  proxy_factory : @ProxyFactory.ProxyFactory
}

///|
/// 创建 AOP 集成器
pub fn AopIntegration::new() -> AopIntegration {
  {
    aspect_registry: @AspectRegistry.AspectRegistry::new(),
    proxy_factory: @ProxyFactory.ProxyFactory::new(),
  }
}

///|
/// 获取切面注册表
pub fn AopIntegration::get_aspect_registry(
  self : AopIntegration,
) -> @AspectRegistry.AspectRegistry {
  self.aspect_registry
}

///|
/// 获取代理工厂
pub fn AopIntegration::get_proxy_factory(
  self : AopIntegration,
) -> @ProxyFactory.ProxyFactory {
  self.proxy_factory
}

///|
/// 注册切点
pub fn AopIntegration::register_pointcut(
  self : AopIntegration,
  name : String,
  pointcut : @Pointcut.Pointcut,
) -> Unit {
  self.aspect_registry.register_pointcut(name, pointcut)
}

///|
/// 注册通知
pub fn AopIntegration::register_advice(
  self : AopIntegration,
  name : String,
  advice : @Advice.Advice,
) -> Unit {
  self.aspect_registry.register_advice(name, advice)
}

///|
/// 注册切面
pub fn AopIntegration::register_aspect(
  self : AopIntegration,
  aspect : @AspectRegistry.Aspect, // ✅ 正确：Aspect 类型通过 AspectRegistry 包访问（同一包内）
) -> Unit {
  // AspectRegistry::register_aspect 需要 Aspect 值类型（同包内）
  // Aspect 和 AspectRegistry 在同一包中，通过 AspectRegistry 包别名访问 Aspect 类型
  self.aspect_registry.register_aspect(aspect)
}

///|
/// 为 Bean 创建代理（如果匹配切面）
/// 
/// 注意：context 参数类型使用 @hashmap.HashMap[String, String] 避免循环依赖
/// 实际使用时，需要传入 ApplicationContext 实例（通过类型擦除）
pub fn AopIntegration::create_proxy_if_needed(
  self : AopIntegration,
  context : @hashmap.HashMap[String, String], // 避免循环依赖，使用 HashMap 代替 ApplicationContext
  bean_name : String,
  bean_class : String,
  methods : Array[String],
) -> Unit {
  // 检查是否有匹配的切面
  let mut has_aspect = false
  methods
  .iter()
  .each(fn(method_name) {
    let matching_aspects = self.aspect_registry.find_matching_aspects(
      bean_name, method_name, bean_class,
    )
    if matching_aspects.length() > 0 {
      has_aspect = true
    }
  })
  if has_aspect {
    // 创建上下文引用（适配类型，避免循环依赖）
    // 简化实现：使用传入的 context（已经是 HashMap），实际应该从 ApplicationContext 提取信息
    let _ctx_ref = context

    // 为每个方法创建拦截器
    methods
    .iter()
    .each(fn(method_name) {
      let matching_aspects = self.aspect_registry.find_matching_aspects(
        bean_name, method_name, bean_class,
      )
      if matching_aspects.length() > 0 {
        // 按顺序执行切面
        matching_aspects
        .iter()
        .each(fn(aspect_name) {
          match self.aspect_registry.find_aspect(aspect_name) {
            Some(aspect) =>
              match self.aspect_registry.find_advice(aspect.advice_name) {
                Some(advice) => {
                  // 创建拦截器
                  // 注意：MethodInterceptor 在 ProxyFactory 包中定义
                  // 需要通过导入的 ProxyFactory alias 访问，但在类型注解中直接使用类型名
                  let advice_fn = advice.advice_fn
                  // 注意：MethodInterceptor 是 ProxyFactory 包中的类型
                  // 由于同包内可以访问，这里需要从 ProxyFactory 获取类型定义
                  // 暂时使用函数类型直接定义
                  let interceptor_fn : (
                    @hashmap.HashMap[String, String],
                    String,
                    String,
                    Array[String],
                    () -> String?,
                  ) -> String? = fn(
                    ctx_ref_param : @hashmap.HashMap[String, String],
                    bean_name : String,
                    method_name : String,
                    args : Array[String],
                    proceed : () -> String?,
                  ) -> String? {
                    // AdviceFn 使用 HashMap，直接使用传入的上下文引用
                    // 根据通知类型执行逻辑
                    match advice.advice_type {
                      Before => {
                        // 前置通知：先执行通知，再执行原方法
                        let _ = advice_fn(
                          ctx_ref_param, bean_name, method_name, args,
                        )
                        proceed()
                      }
                      After => {
                        // 后置通知：先执行原方法，再执行通知
                        let result = proceed()
                        let _ = advice_fn(
                          ctx_ref_param, bean_name, method_name, args,
                        )
                        result
                      }
                      Around =>
                        // 环绕通知：通知函数可以控制是否执行原方法
                        advice_fn(ctx_ref_param, bean_name, method_name, args)
                      AfterReturning => {
                        // 返回后通知：仅在正常返回时执行
                        let result = proceed()
                        if result is Some(_) {
                          let _ = advice_fn(
                            ctx_ref_param, bean_name, method_name, args,
                          )

                        }
                        result
                      }
                      AfterThrowing => {
                        // 异常后通知：仅在异常时执行
                        // 注意：Moonbit 没有异常机制，这里简化实现
                        let result = proceed()
                        // 如果返回 None，可能表示异常
                        if result is None {
                          let _ = advice_fn(
                            ctx_ref_param, bean_name, method_name, args,
                          )

                        }
                        result
                      }
                    }
                  }

                  // 注册拦截器
                  // 注意：interceptor_fn 的类型签名与 MethodInterceptor 匹配
                  // 但需要通过正确的类型转换传递给 add_interceptor
                  self.proxy_factory.add_interceptor(bean_name, interceptor_fn)
                }
                None => ()
              }
            None => ()
          }
        })
      }
    })
  }
}

///|
/// 获取代理 Bean（如果存在）
pub fn AopIntegration::get_proxy(
  self : AopIntegration,
  bean_name : String,
) -> @ProxyFactory.ProxyBean? {
  match self.proxy_factory.create_proxy(bean_name) {
    Some(bean) => Some(bean)
    None => None
  }
}
