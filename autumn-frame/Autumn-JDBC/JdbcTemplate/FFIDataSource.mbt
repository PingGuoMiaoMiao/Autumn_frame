/// FFIDataSource - FFI 数据源实现
/// 
/// 使用 FFI 连接真实数据库（SQLite/MySQL/PostgreSQL）
/// 
/// 注意：
/// - 仅在 native 后端可用（C 后端）
/// - wasm-gc 后端不支持 extern "C" fn
/// - 需要系统安装对应的数据库库（-lsqlite3 -lmysqlclient -lpq）

// ========== FFI 数据源实现 ==========

/// FFI 数据源配置
pub struct FFIDataSourceConfig {
  database_url : String  // 数据库连接字符串
  // SQLite: "sqlite:path/to/database.db"
  // MySQL: "mysql://user:pass@host:port/db"
  // PostgreSQL: "postgresql://user:pass@host:port/db"
} derive(Eq, Show)

/// 创建 FFI 数据源配置
pub fn FFIDataSourceConfig::new(database_url : String) -> FFIDataSourceConfig {
  { database_url, }
}

/// FFI 数据源（SQLite 实现）
/// 
/// 当前实现仅支持 SQLite
/// MySQL 和 PostgreSQL 的实现类似，但需要不同的 FFI 函数
pub struct FFIDataSource {
  config : FFIDataSourceConfig
  db : SqliteHandle?  // SQLite 数据库句柄（使用包内类型）
  is_connected : Bool
}

/// 创建 FFI 数据源
pub fn FFIDataSource::new(config : FFIDataSourceConfig) -> FFIDataSource {
  {
    config,
    db: None,
    is_connected: false
  }
}

/// 连接到数据库（SQLite）
pub fn FFIDataSource::connect(self : FFIDataSource) -> FFIDataSource {
  // 解析数据库 URL
  let url = self.config.database_url
  let db_path = if url.length() >= 7 {
    try {
      if url[:7].to_string() == "sqlite:" {
        // SQLite URL 格式: sqlite:path/to/database.db
        url[7:].to_string()
      } else {
        url
      }
    } catch {
      _ => url
    }
  } else {
    // 假设直接是文件路径
    url
  }
  
  // 打开 SQLite 数据库（使用 DatabaseFFI 接口）
  // 注意：DatabaseFFI 是同一包内的模块，直接使用函数名
  let handle = sqlite3_open_ffi(db_path)
  if handle >= 0 {
    println("  ✅ [FFI数据源] 成功连接到数据库: \{db_path}")
    {
      ..self,
      db: Some(handle),
      is_connected: true
    }
  } else {
    println("  ❌ [FFI数据源] 连接数据库失败: \{db_path}")
    self
  }
}

/// 断开数据库连接
pub fn FFIDataSource::disconnect(self : FFIDataSource) -> FFIDataSource {
  match self.db {
    Some(db) => {
      let _ = sqlite3_close_ffi(db)
      println("  ✅ [FFI数据源] 断开数据库连接")
      {
        ..self,
        db: None,
        is_connected: false
      }
    }
    None => self
  }
}

/// 执行 SQL（不返回结果）
/// 
/// 参数：
/// - sql: SQL 语句
/// 
/// 返回：
/// - Some(affected_rows): 成功，返回受影响的行数
/// - None: 失败
pub fn FFIDataSource::execute(
  self : FFIDataSource,
  sql : String
) -> Int? {
  match self.db {
    Some(db) => {
      let result = sqlite3_exec_ffi(db, sql)
      if result == 0 {
        println("  ✅ [FFI数据源] 执行成功")
        Some(1)  // 简化实现：返回 1 表示成功
      } else {
        let error_msg = sqlite3_errmsg_ffi(db)
        println("  ❌ [FFI数据源] 执行失败: \{error_msg}")
        None
      }
    }
    None => {
      println("  ❌ [FFI数据源] 数据库未连接")
      None
    }
  }
}

/// 查询数据（返回多行）
/// 
/// 参数：
/// - sql: SQL 查询语句
/// - row_mapper: 行映射器
/// 
/// 返回：
/// - Some(results): 成功，返回映射后的结果数组
/// - None: 失败或未找到数据
pub fn FFIDataSource::query(
  self : FFIDataSource,
  sql : String,
  row_mapper : RowMapper
) -> Array[String]? {
  match self.db {
    Some(db) => {
      // 使用 DatabaseFFI 的查询接口
      let empty_params : Array[String] = []
      let fixed_results = sqlite3_query_ffi(db, sql, empty_params)
      // 将 FixedArray[String] 转换为 Array[String]
      let results = Array::from_iter(fixed_results.iter())
      
      if results.length() > 0 {
        // 转换结果：处理所有行
        let result : Array[String] = []
        let result_mut = result
        
        let mut i = 0
        while i < results.length() {
          // 解析每一行结果（格式：key1=value1\tkey2=value2\t...）
          let row_str = results[i]
          let row : @hashmap.HashMap[String, String] = @hashmap.new()
          
          // 解析行字符串（按制表符分隔）
          let parts = Array::from_iter(row_str.split("\t"))
          let mut j = 0
          while j < parts.length() {
            let part = parts[j]
            // 按等号分割键值对
            let kv_parts = Array::from_iter(part.split("="))
            if kv_parts.length() >= 2 {
              let key = kv_parts[0].to_string()
              let value = kv_parts[1].to_string()
              row.set(key, value)
            }
            j = j + 1
          }
          
          // 使用 row_mapper 映射行
          let mapped_row = row_mapper(row)
          result_mut.push(mapped_row)
          i = i + 1
        }
        
        Some(result_mut)
      } else {
        None
      }
    }
    None => {
      println("  ❌ [FFI数据源] 数据库未连接")
      None
    }
  }
}

/// 批量执行 SQL
/// 
/// 参数：
/// - sql: SQL 语句
/// - params_list: 参数列表数组
/// 
/// 返回：
/// - Some(results): 成功，返回影响行数数组
/// - None: 失败
pub fn FFIDataSource::batch_execute(
  self : FFIDataSource,
  sql : String,
  params_list : Array[Array[String]]
) -> Array[Int]? {
  match self.db {
    Some(db) => {
      let result : Array[Int] = []
      let result_mut = result
      
      // 遍历参数列表
      let mut i = 0
      while i < params_list.length() {
        let params = params_list[i]
        
        // 使用带参数的执行接口
        let exec_result = sqlite3_exec_prepared_ffi(db, sql, params)
        if exec_result == 0 {
          result_mut.push(1)  // 简化实现：返回 1 表示成功
        } else {
          result_mut.push(0)
        }
        
        i = i + 1
      }
      
      Some(result_mut)
    }
    None => {
      println("  ❌ [FFI数据源] 数据库未连接")
      None
    }
  }
}
