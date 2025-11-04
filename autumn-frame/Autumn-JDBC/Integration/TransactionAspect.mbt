/// TransactionAspect - 事务切面
/// 
/// 通过 AOP 实现声明式事务支持
/// 
/// 使用方式：
/// 1. 在方法上标记 @Transactional（通过注册切面实现）
/// 2. 自动在方法执行前开始事务
/// 3. 方法执行成功后自动提交事务
/// 4. 方法执行异常时自动回滚事务

// ========== 事务切面实现 ==========

/// 创建事务切面（Before Advice）
/// 
/// 在方法执行前开始事务
pub fn create_transaction_before_advice(
  transaction_manager : @Transaction.TransactionManager,
  _bean_name : String,
  definition : @Transaction.TransactionDefinition
) -> @Advice.Advice {
  @Advice.Advice::before(
    "transactionBefore",
    fn(_ctx : @hashmap.HashMap[String, String], bean_name_param : String, method_name : String, _args : Array[String]) -> String? {
      // 检查是否已存在事务（支持嵌套事务）
      if transaction_manager.has_active_transaction(bean_name_param) {
        println("    🔵 [事务切面] Bean: \{bean_name_param}, 方法: \{method_name}, 加入已存在的事务")
      } else {
        // 开始新事务
        let _ = transaction_manager.begin_transaction(bean_name_param, definition)
        println("    🔵 [事务切面] Bean: \{bean_name_param}, 方法: \{method_name}, 开始新事务")
      }
      None
    },
    1  // 最高优先级，确保在其他切面之前执行
  )
}

/// 创建事务切面（After Advice）
/// 
/// 在方法执行成功后提交事务
pub fn create_transaction_after_advice(
  transaction_manager : @Transaction.TransactionManager,
  _bean_name : String
) -> @Advice.Advice {
  @Advice.Advice::after(
    "transactionAfter",
    fn(_ctx : @hashmap.HashMap[String, String], bean_name_param : String, method_name : String, _args : Array[String]) -> String? {
      // 提交事务
      transaction_manager.commit_transaction(bean_name_param)
      println("    ✅ [事务切面] Bean: \{bean_name_param}, 方法: \{method_name}, 提交事务")
      None
    },
    100  // 较低优先级，确保在其他切面之后执行
  )
}

/// 创建事务切面（AfterThrowing Advice）
/// 
/// 在方法执行异常时回滚事务
pub fn create_transaction_after_throwing_advice(
  transaction_manager : @Transaction.TransactionManager,
  _bean_name : String
) -> @Advice.Advice {
  @Advice.Advice::after_throwing(
    "transactionAfterThrowing",
    fn(_ctx : @hashmap.HashMap[String, String], bean_name_param : String, method_name : String, _args : Array[String]) -> String? {
      // 回滚事务
      transaction_manager.rollback_transaction(bean_name_param)
      println("    ❌ [事务切面] Bean: \{bean_name_param}, 方法: \{method_name}, 回滚事务（异常）")
      None
    },
    100  // 较低优先级
  )
}

/// 为 Bean 的方法注册事务切面
/// 
/// 参数：
/// - aop_integration: AOP 集成器
/// - transaction_manager: 事务管理器
/// - bean_name: Bean 名称
/// - method_names: 需要事务支持的方法名称列表
/// - definition: 事务定义
pub fn register_transaction_aspect(
  aop_integration : @AopIntegration.AopIntegration,
  transaction_manager : @Transaction.TransactionManager,
  bean_name : String,
  method_names : Array[String],
  definition : @Transaction.TransactionDefinition
) -> Unit {
  // 1. 注册 Before Advice（开始事务）
  let before_advice = create_transaction_before_advice(transaction_manager, bean_name, definition)
  let before_advice_name = bean_name + "_transaction_before"
  aop_integration.register_advice(before_advice_name, before_advice)
  
  // 2. 注册 After Advice（提交事务）
  let after_advice = create_transaction_after_advice(transaction_manager, bean_name)
  let after_advice_name = bean_name + "_transaction_after"
  aop_integration.register_advice(after_advice_name, after_advice)
  
  // 3. 注册 AfterThrowing Advice（回滚事务）
  let after_throwing_advice = create_transaction_after_throwing_advice(transaction_manager, bean_name)
  let after_throwing_advice_name = bean_name + "_transaction_after_throwing"
  aop_integration.register_advice(after_throwing_advice_name, after_throwing_advice)
  
  // 4. 为每个方法创建切点
  let mut i = 0
  while i < method_names.length() {
    let method_name = method_names[i]
    
    // 创建方法名切点
    let pointcut_name = bean_name + "_" + method_name + "_pointcut"
    let pointcut = @Pointcut.Pointcut::method_name(pointcut_name, method_name, i + 1)
    aop_integration.register_pointcut(pointcut_name, pointcut)
    
    // 创建切面（组合切点和通知）
    // Before 切面
    let before_aspect = @AspectRegistry.Aspect::new(
      bean_name + "_" + method_name + "_transaction_before_aspect",
      pointcut_name,
      before_advice_name,
      i * 3 + 1
    )
    aop_integration.register_aspect(before_aspect)
    
    // After 切面
    let after_aspect = @AspectRegistry.Aspect::new(
      bean_name + "_" + method_name + "_transaction_after_aspect",
      pointcut_name,
      after_advice_name,
      i * 3 + 2
    )
    aop_integration.register_aspect(after_aspect)
    
    // AfterThrowing 切面
    let after_throwing_aspect = @AspectRegistry.Aspect::new(
      bean_name + "_" + method_name + "_transaction_after_throwing_aspect",
      pointcut_name,
      after_throwing_advice_name,
      i * 3 + 3
    )
    aop_integration.register_aspect(after_throwing_aspect)
    
    i = i + 1
  }
  
  println("  ✅ 为 Bean \{bean_name} 注册事务切面（方法数量: \{method_names.length()}）")
}

