/// MySQLDataSource - MySQL FFI 数据源实现
/// 
/// 使用 FFI 连接真实 MySQL 数据库
/// 
/// 注意：
/// - 仅在 native 后端可用（C 后端）
/// - wasm-gc 后端不支持 extern "C" fn
/// - 需要系统安装 MySQL C 客户端库（-lmysqlclient）

// ========== MySQL FFI 数据源实现 ==========

///|
/// MySQL 数据源配置
pub struct MySQLDataSourceConfig {
  host : String
  port : Int
  user : String
  password : String
  database : String
} derive(Eq, Show)

///|
/// 创建 MySQL 数据源配置
pub fn MySQLDataSourceConfig::new(
  host : String,
  port : Int,
  user : String,
  password : String,
  database : String,
) -> MySQLDataSourceConfig {
  { host, port, user, password, database }
}

///|
/// MySQL 数据源
pub struct MySQLDataSource {
  config : MySQLDataSourceConfig
  db : Int? // MySQL 数据库句柄（使用 Int 类型）
  is_connected : Bool
}

///|
/// 创建 MySQL 数据源
pub fn MySQLDataSource::new(config : MySQLDataSourceConfig) -> MySQLDataSource {
  { config, db: None, is_connected: false }
}

///|
/// 连接到数据库（MySQL）
pub fn MySQLDataSource::connect(self : MySQLDataSource) -> MySQLDataSource {
  let handle = mysql_connect_ffi(
    self.config.host,
    self.config.port,
    self.config.user,
    self.config.password,
    self.config.database,
  )
  if handle >= 0 {
    println(
      "  ✅ [MySQL数据源] 成功连接到数据库: \{self.config.database}@\{self.config.host}:\{self.config.port}",
    )
    { ..self, db: Some(handle), is_connected: true }
  } else {
    println(
      "  ❌ [MySQL数据源] 连接数据库失败: \{self.config.database}@\{self.config.host}:\{self.config.port}",
    )
    self
  }
}

///|
/// 断开数据库连接
pub fn MySQLDataSource::disconnect(self : MySQLDataSource) -> MySQLDataSource {
  match self.db {
    Some(db) => {
      let _ = mysql_close_ffi(db)
      println("  ✅ [MySQL数据源] 断开数据库连接")
      { ..self, db: None, is_connected: false }
    }
    None => self
  }
}

///|
/// 执行 SQL（不返回结果）
/// 
/// 参数：
/// - sql: SQL 语句
/// 
/// 返回：
/// - Some(affected_rows): 成功，返回受影响的行数
/// - None: 失败
pub fn MySQLDataSource::execute(self : MySQLDataSource, sql : String) -> Int? {
  match self.db {
    Some(db) => {
      let result = mysql_execute_ffi(db, sql)
      if result == 0 {
        println("  ✅ [MySQL数据源] 执行成功")
        Some(1) // 简化实现：返回 1 表示成功
      } else {
        let error_msg = mysql_errmsg_ffi(db)
        println("  ❌ [MySQL数据源] 执行失败: \{error_msg}")
        None
      }
    }
    None => {
      println("  ❌ [MySQL数据源] 数据库未连接")
      None
    }
  }
}

///|
/// 查询数据（返回多行）
/// 
/// 参数：
/// - sql: SQL 查询语句
/// - row_mapper: 行映射器
/// 
/// 返回：
/// - Some(results): 成功，返回映射后的结果数组
/// - None: 失败或未找到数据
pub fn MySQLDataSource::query(
  self : MySQLDataSource,
  sql : String,
  row_mapper : RowMapper,
) -> Array[String]? {
  println("  🔍 [MySQL数据源] 开始查询: " + sql)
  match self.db {
    Some(db) => {
      // 使用 MySQL FFI 的查询接口（返回 FixedArray[String]）
      let empty_params : Array[String] = []
      println(
        "  🔍 [MySQL数据源] 调用 mysql_query_ffi, handle=" +
        db.to_string(),
      )
      let fixed_results = mysql_query_ffi(db, sql, empty_params)
      println(
        "  🔍 [MySQL数据源] 查询完成, FixedArray 结果数量=" +
        fixed_results.length().to_string(),
      )

      // 将 FixedArray[String] 转换为 Array[String]
      // 根据 MoonBit Array Package 文档，使用 Array::from_iter 从 FixedArray 的迭代器创建 Array
      let results = Array::from_iter(fixed_results.iter())
      println(
        "  🔍 [MySQL数据源] 转换为 Array 后, 结果数量=" +
        results.length().to_string(),
      )
      if results.length() > 0 {
        // 转换结果：处理所有行
        let result : Array[String] = []
        let result_mut = result
        let mut i = 0
        while i < results.length() {
          let row_str = results[i]
          // 解析行数据（格式：key1=value1\tkey2=value2）
          let row : @hashmap.HashMap[String, String] = @hashmap.new()
          // 解析行字符串（制表符分隔的 key=value 对）
          // split 返回 Iter[StringView]，需要转换为数组
          let tab_str = "\t"
          let parts_iter = row_str.split(tab_str)
          let parts_array = parts_iter.to_array()
          let mut j = 0
          while j < parts_array.length() {
            let part = parts_array[j]
            // 分割 key=value
            let eq_str = "="
            let kv_iter = part.split(eq_str)
            let kv_array = kv_iter.to_array()
            if kv_array.length() >= 2 {
              let key = kv_array[0].to_string()
              let value = kv_array[1].to_string()
              row.set(key, value)
            }
            j = j + 1
          }
          result_mut.push(row_mapper(row))
          i = i + 1
        }
        Some(result_mut)
      } else {
        None
      }
    }
    None => {
      println("  ❌ [MySQL数据源] 数据库未连接")
      None
    }
  }
}
