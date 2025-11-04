/// MemoryDataSource - 内存数据源实现
/// 
/// 提供内存数据库的数据源实现
/// 
/// 使用方式：
/// ```moonbit
/// let database = MemoryDatabase::new()
/// let data_source = MemoryDataSource::new(database)
/// let jdbc_template = JdbcTemplate::new(fn() { data_source.get_connection() })
/// ```

// ========== 导入依赖 ==========

// MemoryDatabase 在同一包内，直接使用

// ========== 数据结构 ==========

/// 内存数据源
pub struct MemoryDataSource {
  database : MemoryDatabase
  // 事务 ID（如果当前连接在事务中）
  current_transaction_id : String?
}

/// 创建内存数据源
pub fn MemoryDataSource::new(database : MemoryDatabase) -> MemoryDataSource {
  {
    database,
    current_transaction_id: None
  }
}

/// 从数据源获取连接
/// 
/// 返回的 Connection 包含数据库引用
pub fn MemoryDataSource::get_connection(self : MemoryDataSource) -> Connection {
  // Connection 需要包含数据库引用和事务 ID
  // 但由于 Connection 结构体的限制，我们使用 connection_id 来传递信息
  // 实际使用时，需要通过其他方式传递数据库引用
  
  // 简化实现：使用特殊的 connection_id 标识
  let conn_id = match self.current_transaction_id {
    Some(tx_id) => "memory_db_tx_" + tx_id
    None => "memory_db"
  }
  
  Connection::new(conn_id)
}

/// 获取数据库引用
pub fn MemoryDataSource::get_database(self : MemoryDataSource) -> MemoryDatabase {
  self.database
}

/// 设置当前事务 ID
pub fn MemoryDataSource::set_transaction_id(
  self : MemoryDataSource,
  transaction_id : String?
) -> MemoryDataSource {
  {
    ..self,
    current_transaction_id: transaction_id
  }
}

