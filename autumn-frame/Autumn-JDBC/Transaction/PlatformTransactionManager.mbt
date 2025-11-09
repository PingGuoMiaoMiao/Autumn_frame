/// PlatformTransactionManager - 平台事务管理器接口
/// 
/// 定义事务管理的基本操作

// ========== 事务状态 ==========

///|
/// 事务状态
pub enum TransactionStatus {
  Active // 活动状态
  Committed // 已提交
  RolledBack // 已回滚
  Unknown // 未知状态
} derive(Eq, Show)

///|
/// 事务对象
pub struct Transaction {
  transaction_id : String
  status : TransactionStatus
}

///|
/// 创建事务
pub fn Transaction::new(
  transaction_id : String,
  status : TransactionStatus,
) -> Transaction {
  { transaction_id, status }
}

///|
/// 获取事务 ID
pub fn Transaction::get_id(self : Transaction) -> String {
  self.transaction_id
}

///|
/// 获取事务状态
pub fn Transaction::get_status(self : Transaction) -> TransactionStatus {
  self.status
}

// ========== 事务管理器接口 ==========

///|
/// 获取当前事务
/// 
/// 返回值：
/// - Some(transaction): 存在事务
/// - None: 不存在事务
pub type GetTransaction = () -> Transaction?

///|
/// 开始事务
/// 
/// 参数：
/// - definition: 事务定义
/// 
/// 返回值：
/// - 事务对象
pub type BeginTransaction = (TransactionDefinition) -> Transaction

///|
/// 提交事务
/// 
/// 参数：
/// - transaction: 事务对象
pub type CommitTransaction = (Transaction) -> Unit

///|
/// 回滚事务
/// 
/// 参数：
/// - transaction: 事务对象
pub type RollbackTransaction = (Transaction) -> Unit
