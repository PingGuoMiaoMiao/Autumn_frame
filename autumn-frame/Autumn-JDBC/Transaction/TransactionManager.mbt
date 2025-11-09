/// TransactionManager - 事务管理器实现
/// 
/// 管理数据库事务的创建、提交和回滚

// ========== 导入依赖 ==========

// ========== 事务管理器 ==========

///|
/// 事务管理器
pub struct TransactionManager {
  // 当前活动的事务栈（支持嵌套事务）
  active_transactions : @hashmap.HashMap[String, Transaction]

  // 事务计数器（用于生成唯一事务 ID）
  mut transaction_counter : Int
}

///|
/// 创建事务管理器
pub fn TransactionManager::new() -> TransactionManager {
  { active_transactions: @hashmap.new(), transaction_counter: 0 }
}

// ========== 事务管理方法 ==========

///|
/// 获取当前事务
/// 
/// 参数：
/// - bean_name: Bean 名称（用于标识事务上下文）
/// 
/// 返回值：
/// - Some(transaction): 存在事务
/// - None: 不存在事务
pub fn TransactionManager::get_transaction(
  self : TransactionManager,
  bean_name : String,
) -> Transaction? {
  self.active_transactions.get(bean_name)
}

///|
/// 开始事务
/// 
/// 参数：
/// - bean_name: Bean 名称（用于标识事务上下文）
/// - definition: 事务定义
/// 
/// 返回值：
/// - 事务对象
pub fn TransactionManager::begin_transaction(
  self : TransactionManager,
  bean_name : String,
  _definition : TransactionDefinition,
) -> Transaction {
  // 生成唯一事务 ID
  self.transaction_counter = self.transaction_counter + 1
  let transaction_id = "tx_" +
    bean_name +
    "_" +
    self.transaction_counter.to_string()

  // 创建事务对象
  let transaction = Transaction::new(transaction_id, Active)

  // 存储活动事务
  self.active_transactions.set(bean_name, transaction)
  println("  🔵 开始事务: \{transaction_id} (Bean: \{bean_name})")
  transaction
}

///|
/// 提交事务
/// 
/// 参数：
/// - bean_name: Bean 名称
pub fn TransactionManager::commit_transaction(
  self : TransactionManager,
  bean_name : String,
) -> Unit {
  match self.active_transactions.get(bean_name) {
    Some(transaction) => {
      println(
        "  ✅ 提交事务: \{transaction.get_id()} (Bean: \{bean_name})",
      )

      // 移除已提交的事务
      self.active_transactions.remove(bean_name)
    }
    None => println("  ⚠️  事务不存在: \{bean_name}")
  }
}

///|
/// 回滚事务
/// 
/// 参数：
/// - bean_name: Bean 名称
pub fn TransactionManager::rollback_transaction(
  self : TransactionManager,
  bean_name : String,
) -> Unit {
  match self.active_transactions.get(bean_name) {
    Some(transaction) => {
      println(
        "  ❌ 回滚事务: \{transaction.get_id()} (Bean: \{bean_name})",
      )

      // 移除已回滚的事务
      self.active_transactions.remove(bean_name)
    }
    None => println("  ⚠️  事务不存在: \{bean_name}")
  }
}

///|
/// 检查是否存在活动事务
/// 
/// 参数：
/// - bean_name: Bean 名称
/// 
/// 返回值：
/// - true: 存在活动事务
/// - false: 不存在活动事务
pub fn TransactionManager::has_active_transaction(
  self : TransactionManager,
  bean_name : String,
) -> Bool {
  match self.active_transactions.get(bean_name) {
    Some(transaction) =>
      match transaction.get_status() {
        Active => true
        _ => false
      }
    None => false
  }
}
