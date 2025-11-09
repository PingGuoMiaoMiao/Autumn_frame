/// DataAccessException - 数据访问异常
/// 
/// 定义统一的异常类型，用于处理数据库访问相关的错误
/// 
/// 异常层次结构：
/// - DataAccessException（基类）
///   - InvalidDataAccessResourceUsageException（资源使用错误）
///   - DataRetrievalFailureException（数据检索失败）
///   - DataIntegrityViolationException（数据完整性违规）
///   - CannotAcquireLockException（无法获取锁）
///   - DeadlockLoserDataAccessException（死锁）
///   - QueryTimeoutException（查询超时）
///   - TransientDataAccessException（临时数据访问异常）

///|
/// 数据访问异常
pub enum DataAccessException {
  DataAccessException(String) // 通用数据访问异常
  InvalidDataAccessResourceUsageException(String) // 资源使用错误（如：权限不足、表不存在）
  DataRetrievalFailureException(String) // 数据检索失败（如：查询失败）
  DataIntegrityViolationException(String) // 数据完整性违规（如：唯一约束冲突）
  CannotAcquireLockException(String) // 无法获取锁（如：锁超时）
  DeadlockLoserDataAccessException(String) // 死锁（如：事务死锁）
  QueryTimeoutException(String) // 查询超时
  TransientDataAccessException(String) // 临时数据访问异常（可重试）
} derive(Eq, Show)

///|
/// 获取异常消息
pub fn DataAccessException::get_message(self : DataAccessException) -> String {
  match self {
    DataAccessException(msg) => msg
    InvalidDataAccessResourceUsageException(msg) => "资源使用错误: " + msg
    DataRetrievalFailureException(msg) => "数据检索失败: " + msg
    DataIntegrityViolationException(msg) => "数据完整性违规: " + msg
    CannotAcquireLockException(msg) => "无法获取锁: " + msg
    DeadlockLoserDataAccessException(msg) => "死锁: " + msg
    QueryTimeoutException(msg) => "查询超时: " + msg
    TransientDataAccessException(msg) => "临时数据访问异常: " + msg
  }
}

///|
/// 转换为字符串（用于日志记录）
pub fn DataAccessException::to_string(self : DataAccessException) -> String {
  match self {
    DataAccessException(msg) => "DataAccessException: " + msg
    InvalidDataAccessResourceUsageException(msg) =>
      "InvalidDataAccessResourceUsageException: " + msg
    DataRetrievalFailureException(msg) =>
      "DataRetrievalFailureException: " + msg
    DataIntegrityViolationException(msg) =>
      "DataIntegrityViolationException: " + msg
    CannotAcquireLockException(msg) => "CannotAcquireLockException: " + msg
    DeadlockLoserDataAccessException(msg) =>
      "DeadlockLoserDataAccessException: " + msg
    QueryTimeoutException(msg) => "QueryTimeoutException: " + msg
    TransientDataAccessException(msg) => "TransientDataAccessException: " + msg
  }
}

///|
/// 检查是否是临时异常（可重试）
pub fn DataAccessException::is_transient(self : DataAccessException) -> Bool {
  match self {
    TransientDataAccessException(_) => true
    DeadlockLoserDataAccessException(_) => true // 死锁通常可以重试
    QueryTimeoutException(_) => true // 超时通常可以重试
    _ => false
  }
}
