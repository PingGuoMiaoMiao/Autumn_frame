/// SQLErrorCodeTranslator - SQL 错误码转换器
/// 
/// 将数据库特定的错误码转换为统一的 DataAccessException
/// 
/// 支持数据库：
/// - MySQL
/// - SQLite
/// 
/// 使用示例：
/// ```moonbit
/// let translator = SQLErrorCodeTranslator::new()
/// match translator.translate_mysql_error(1062, "Duplicate entry") {
///   DataIntegrityViolationException(msg) => println("数据完整性错误: " + msg)
///   _ => ()
/// }
/// ```

// ========== 错误码转换器类型 ==========

///|
/// 错误码转换函数类型
pub type ErrorCodeTranslator = (String) -> DataAccessException

///|
/// SQL 错误码转换器
pub struct SQLErrorCodeTranslator {
  // MySQL 错误码映射
  mysql_error_map : @hashmap.HashMap[Int, ErrorCodeTranslator]
  // SQLite 错误码映射
  sqlite_error_map : @hashmap.HashMap[Int, ErrorCodeTranslator]
}

///|
/// 创建错误码转换器
pub fn SQLErrorCodeTranslator::new() -> SQLErrorCodeTranslator {
  let mysql_map = @hashmap.new()
  let sqlite_map = @hashmap.new()

  // ========== MySQL 错误码映射 ==========

  // 1045: Access denied for user
  mysql_map.set(1045, fn(msg) {
    InvalidDataAccessResourceUsageException("访问被拒绝: " + msg)
  })

  // 1054: Unknown column
  mysql_map.set(1054, fn(msg) {
    InvalidDataAccessResourceUsageException("未知列: " + msg)
  })

  // 1062: Duplicate entry（唯一约束冲突）
  mysql_map.set(1062, fn(msg) {
    DataIntegrityViolationException("重复条目: " + msg)
  })

  // 1064: SQL syntax error
  mysql_map.set(1064, fn(msg) {
    InvalidDataAccessResourceUsageException("SQL 语法错误: " + msg)
  })

  // 1146: Table doesn't exist
  mysql_map.set(1146, fn(msg) {
    InvalidDataAccessResourceUsageException("表不存在: " + msg)
  })

  // 1205: Lock wait timeout exceeded
  mysql_map.set(1205, fn(msg) {
    CannotAcquireLockException("锁等待超时: " + msg)
  })

  // 1213: Deadlock found
  mysql_map.set(1213, fn(msg) {
    DeadlockLoserDataAccessException("死锁: " + msg)
  })

  // 2013: Lost connection to MySQL server
  mysql_map.set(2013, fn(msg) {
    TransientDataAccessException("连接丢失: " + msg)
  })

  // ========== SQLite 错误码映射 ==========

  // 1: SQLITE_ERROR（通用错误）
  sqlite_map.set(1, fn(msg) {
    InvalidDataAccessResourceUsageException("SQLite 错误: " + msg)
  })

  // 2: SQLITE_INTERNAL（内部错误）
  sqlite_map.set(2, fn(msg) {
    DataAccessException("SQLite 内部错误: " + msg)
  })

  // 3: SQLITE_PERM（权限错误）
  sqlite_map.set(3, fn(msg) {
    InvalidDataAccessResourceUsageException("权限错误: " + msg)
  })

  // 4: SQLITE_ABORT（操作中止）
  sqlite_map.set(4, fn(msg) {
    TransientDataAccessException("操作中止: " + msg)
  })

  // 5: SQLITE_BUSY（数据库被锁定）
  sqlite_map.set(5, fn(msg) {
    CannotAcquireLockException("数据库被锁定: " + msg)
  })

  // 6: SQLITE_LOCKED（表被锁定）
  sqlite_map.set(6, fn(msg) {
    CannotAcquireLockException("表被锁定: " + msg)
  })

  // 8: SQLITE_READONLY（数据库只读）
  sqlite_map.set(8, fn(msg) {
    InvalidDataAccessResourceUsageException("数据库只读: " + msg)
  })

  // 11: SQLITE_CORRUPT（数据库损坏）
  sqlite_map.set(11, fn(msg) { DataAccessException("数据库损坏: " + msg) })

  // 19: SQLITE_CONSTRAINT（约束违反）
  sqlite_map.set(19, fn(msg) {
    DataIntegrityViolationException("约束违反: " + msg)
  })

  // 20: SQLITE_MISMATCH（数据类型不匹配）
  sqlite_map.set(20, fn(msg) {
    InvalidDataAccessResourceUsageException("数据类型不匹配: " + msg)
  })

  // 21: SQLITE_MISUSE（API 使用错误）
  sqlite_map.set(21, fn(msg) {
    InvalidDataAccessResourceUsageException("API 使用错误: " + msg)
  })

  // 23: SQLITE_AUTH（授权失败）
  sqlite_map.set(23, fn(msg) {
    InvalidDataAccessResourceUsageException("授权失败: " + msg)
  })
  { mysql_error_map: mysql_map, sqlite_error_map: sqlite_map }
}

// ========== 错误码转换方法 ==========

///|
/// 转换 MySQL 错误码
/// 
/// 参数：
/// - error_code: MySQL 错误码
/// - error_message: 错误消息
/// 
/// 返回值：
/// - DataAccessException 异常
pub fn SQLErrorCodeTranslator::translate_mysql_error(
  self : SQLErrorCodeTranslator,
  error_code : Int,
  error_message : String,
) -> DataAccessException {
  match self.mysql_error_map.get(error_code) {
    Some(translator) => translator(error_message)
    None =>
      DataAccessException(
        "MySQL错误 " + error_code.to_string() + ": " + error_message,
      )
  }
}

///|
/// 转换 SQLite 错误码
/// 
/// 参数：
/// - error_code: SQLite 错误码
/// - error_message: 错误消息
/// 
/// 返回值：
/// - DataAccessException 异常
pub fn SQLErrorCodeTranslator::translate_sqlite_error(
  self : SQLErrorCodeTranslator,
  error_code : Int,
  error_message : String,
) -> DataAccessException {
  match self.sqlite_error_map.get(error_code) {
    Some(translator) => translator(error_message)
    None =>
      DataAccessException(
        "SQLite错误 " + error_code.to_string() + ": " + error_message,
      )
  }
}

///|
/// 从错误消息中提取错误码（MySQL）
/// 
/// 简化实现：从错误消息中尝试提取错误码
/// 实际使用时，应该从数据库驱动获取原始错误码
fn extract_mysql_error_code(error_message : String) -> Int? {
  // MySQL 错误消息格式通常是：Error 1062: Duplicate entry
  // 简化实现：尝试查找 "Error " 后的数字
  let prefix = "Error "
  match error_message.find(prefix) {
    Some(pos) => {
      let start_pos = pos + prefix.length()
      let mut error_code_str = ""
      let mut i = start_pos
      while i < error_message.length() {
        let c = error_message[i].unsafe_to_char()
        if c >= '0' && c <= '9' {
          error_code_str = error_code_str + c.to_string()
          i = i + 1
        } else {
          break
        }
      }
      if error_code_str.length() > 0 {
        // 简化实现：手动解析整数
        let mut code = 0
        let mut i = 0
        while i < error_code_str.length() {
          let c = error_code_str[i].unsafe_to_char()
          if c >= '0' && c <= '9' {
            code = code * 10 + (c.to_int() - '0'.to_int())
            i = i + 1
          } else {
            return None
          }
        }
        Some(code)
      } else {
        None
      }
    }
    None => None
  }
}

///|
/// 从错误消息中提取错误码（SQLite）
fn extract_sqlite_error_code(error_message : String) -> Int? {
  // SQLite 错误消息格式通常是：SQLITE_CONSTRAINT: UNIQUE constraint failed
  // 简化实现：尝试查找 SQLITE_ 前缀后的错误码名称，然后映射到错误码
  // 实际使用时，应该从数据库驱动获取原始错误码
  if error_message.has_prefix("SQLITE_CONSTRAINT") {
    Some(19)
  } else if error_message.has_prefix("SQLITE_BUSY") {
    Some(5)
  } else if error_message.has_prefix("SQLITE_LOCKED") {
    Some(6)
  } else if error_message.has_prefix("SQLITE_READONLY") {
    Some(8)
  } else {
    None
  }
}

///|
/// 转换 MySQL 错误消息（自动提取错误码）
pub fn SQLErrorCodeTranslator::translate_mysql_error_message(
  self : SQLErrorCodeTranslator,
  error_message : String,
) -> DataAccessException {
  match extract_mysql_error_code(error_message) {
    Some(error_code) => self.translate_mysql_error(error_code, error_message)
    None => DataAccessException("MySQL错误: " + error_message)
  }
}

///|
/// 转换 SQLite 错误消息（自动提取错误码）
pub fn SQLErrorCodeTranslator::translate_sqlite_error_message(
  self : SQLErrorCodeTranslator,
  error_message : String,
) -> DataAccessException {
  match extract_sqlite_error_code(error_message) {
    Some(error_code) => self.translate_sqlite_error(error_code, error_message)
    None => DataAccessException("SQLite错误: " + error_message)
  }
}
