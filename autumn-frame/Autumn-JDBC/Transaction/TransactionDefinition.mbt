/// TransactionDefinition - 事务定义
/// 
/// 定义事务的属性（隔离级别、传播行为、超时等）

// ========== 隔离级别 ==========

///|
/// 事务隔离级别
pub enum IsolationLevel {
  Default // 使用数据库默认隔离级别
  ReadUncommitted // 读未提交（最低隔离级别）
  ReadCommitted // 读已提交
  RepeatableRead // 可重复读
  Serializable // 串行化（最高隔离级别）
} derive(Eq, Show)

// ========== 传播行为 ==========

///|
/// 事务传播行为
pub enum Propagation {
  Required // 如果当前存在事务，则加入该事务；如果当前不存在事务，则创建一个新的事务
  Supports // 如果当前存在事务，则加入该事务；如果当前不存在事务，则以非事务的方式继续运行
  Mandatory // 如果当前存在事务，则加入该事务；如果当前不存在事务，则抛出异常
  RequiresNew // 创建一个新的事务，如果当前存在事务，则把当前事务挂起
  NotSupported // 以非事务方式运行，如果当前存在事务，则把当前事务挂起
  Never // 以非事务方式运行，如果当前存在事务，则抛出异常
  Nested // 如果当前存在事务，则创建一个事务作为当前事务的嵌套事务来运行；如果当前没有事务，则等价于 Required
} derive(Eq, Show)

// ========== 事务定义 ==========

///|
/// 事务定义
pub struct TransactionDefinition {
  isolation_level : IsolationLevel // 隔离级别
  propagation : Propagation // 传播行为
  timeout : Int? // 超时时间（秒），None 表示使用默认值
  read_only : Bool // 是否只读
}

///|
/// 创建事务定义
pub fn TransactionDefinition::new(
  isolation_level : IsolationLevel,
  propagation : Propagation,
  timeout : Int?,
  read_only : Bool,
) -> TransactionDefinition {
  { isolation_level, propagation, timeout, read_only }
}

///|
/// 创建默认事务定义
pub fn TransactionDefinition::default() -> TransactionDefinition {
  {
    isolation_level: Default,
    propagation: Required,
    timeout: None,
    read_only: false,
  }
}

///|
/// 获取隔离级别
pub fn TransactionDefinition::get_isolation_level(
  self : TransactionDefinition,
) -> IsolationLevel {
  self.isolation_level
}

///|
/// 获取传播行为
pub fn TransactionDefinition::get_propagation(
  self : TransactionDefinition,
) -> Propagation {
  self.propagation
}

///|
/// 获取超时时间
pub fn TransactionDefinition::get_timeout(self : TransactionDefinition) -> Int? {
  self.timeout
}

///|
/// 是否只读
pub fn TransactionDefinition::is_read_only(
  self : TransactionDefinition,
) -> Bool {
  self.read_only
}
