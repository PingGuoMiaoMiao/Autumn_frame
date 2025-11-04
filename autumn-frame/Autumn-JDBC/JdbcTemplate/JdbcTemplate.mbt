/// JdbcTemplate - JDBC 模板类
/// 
/// 简化 JDBC 操作，提供便捷的数据库访问方法

// ========== JdbcTemplate 结构 ==========

/// JdbcTemplate
pub struct JdbcTemplate {
  data_source_fn : DataSource  // 数据源（函数类型）
  // 可选的数据库引用（用于内存数据库）
  // 注意：由于 MemoryDatabase 是不可变的，每次操作后需要更新引用
  mut database_ref : MemoryDatabase?
}

/// 创建 JdbcTemplate（从数据源函数）
pub fn JdbcTemplate::new(data_source_fn : DataSource) -> JdbcTemplate {
  {
    data_source_fn,
    database_ref: None
  }
}

/// 创建 JdbcTemplate（从内存数据库）
pub fn JdbcTemplate::new_with_memory_database(database : MemoryDatabase) -> JdbcTemplate {
  // 创建一个数据源函数，返回标识连接的 Connection
  let data_source_fn : DataSource = fn() {
    Connection::new("memory_db")
  }
  { data_source_fn, database_ref: Some(database) }
}

// ========== 核心方法 ==========

/// 执行 SQL（不返回结果）
/// 
/// 参数：
/// - sql: SQL 语句
/// - params: 参数数组（顺序对应 SQL 中的 ?）
/// 
/// 返回值：
/// - 影响的行数
pub fn JdbcTemplate::execute(
  self : JdbcTemplate,
  sql : String,
  params : Array[String]
) -> Int {
  // 检查是否使用内存数据库
  match self.database_ref {
    Some(db) => {
      // 使用内存数据库执行 SQL
      let (result, updated_db) = db.execute(sql, params)
      // 更新数据库引用（保存状态）
      self.database_ref = Some(updated_db)
      result
    }
    None => {
      // 使用传统数据源（模拟实现）
      println("  📝 执行 SQL: \{sql}")
      println("  📋 参数: \{params.length()} 个")
      println("  ⚠️  使用模拟数据源，实际需要使用内存数据库")
      0  // 模拟影响行数
    }
  }
}

/// 查询并映射为单个对象
/// 
/// 参数：
/// - sql: SQL 语句
/// - params: 参数数组
/// - row_mapper: 行映射器
/// 
/// 返回值：
/// - Some(对象): 查询成功
/// - None: 未找到记录
pub fn JdbcTemplate::query(
  self : JdbcTemplate,
  sql : String,
  params : Array[String],
  row_mapper : RowMapper
) -> String? {
  // 检查是否使用内存数据库
  match self.database_ref {
    Some(db) => {
      // 使用内存数据库查询
      let rows = db.query(sql, params)
      if rows.length() > 0 {
        Some(row_mapper(rows[0]))
      } else {
        None
      }
    }
    None => {
      // 使用传统数据源（模拟实现）
      println("  📝 查询 SQL: \{sql}")
      println("  📋 参数: \{params.length()} 个")
      println("  ⚠️  使用模拟数据源，实际需要使用内存数据库")
      
      // 创建模拟行数据
      let mock_row : @hashmap.HashMap[String, String] = @hashmap.new()
      mock_row.set("id", "1")
      mock_row.set("name", "test")
      
      Some(row_mapper(mock_row))
    }
  }
}

/// 查询并映射为列表
/// 
/// 参数：
/// - sql: SQL 语句
/// - params: 参数数组
/// - row_mapper: 行映射器
/// 
/// 返回值：
/// - 对象列表
pub fn JdbcTemplate::query_for_list(
  self : JdbcTemplate,
  sql : String,
  params : Array[String],
  row_mapper : RowMapper
) -> Array[String] {
  // 检查是否使用内存数据库
  match self.database_ref {
    Some(db) => {
      // 使用内存数据库查询
      let rows = db.query(sql, params)
         let result : Array[String] = []
         let result_mut = result
      let mut i = 0
      while i < rows.length() {
        result_mut.push(row_mapper(rows[i]))
        i = i + 1
      }
      result_mut
    }
    None => {
      // 使用传统数据源（模拟实现）
      println("  📝 查询列表 SQL: \{sql}")
      println("  📋 参数: \{params.length()} 个")
      println("  ⚠️  使用模拟数据源，实际需要使用内存数据库")
      
      // 创建模拟行数据
      let mock_row : @hashmap.HashMap[String, String] = @hashmap.new()
      mock_row.set("id", "1")
      mock_row.set("name", "test")
      
      [row_mapper(mock_row)]
    }
  }
}

/// 更新操作（INSERT/UPDATE/DELETE）
/// 
/// 参数：
/// - sql: SQL 语句
/// - params: 参数数组
/// 
/// 返回值：
/// - 影响的行数
pub fn JdbcTemplate::update(
  self : JdbcTemplate,
  sql : String,
  params : Array[String]
) -> Int {
  // 检查是否使用内存数据库
  match self.database_ref {
    Some(db) => {
      // 使用内存数据库执行更新
      let (result, updated_db) = db.execute(sql, params)
      // 更新数据库引用
      self.database_ref = Some(updated_db)
      result
    }
    None => {
      // 使用传统数据源（模拟实现）
      println("  📝 更新 SQL: \{sql}")
      println("  📋 参数: \{params.length()} 个")
      println("  ⚠️  使用模拟数据源，实际需要使用内存数据库")
      1  // 模拟影响行数
    }
  }
}

/// 批量更新
/// 
/// 参数：
/// - sql: SQL 语句（使用 ? 作为占位符）
/// - params_list: 参数列表数组（每个元素是一个参数数组）
/// 
/// 返回值：
/// - 每条语句影响的行数数组
pub fn JdbcTemplate::batch_update(
  self : JdbcTemplate,
  sql : String,
  params_list : Array[Array[String]]
) -> Array[Int] {
  // 检查是否使用内存数据库
  match self.database_ref {
    Some(db) => {
      // 使用内存数据库批量执行
      let result : Array[Int] = []
      let result_mut = result
      let mut current_db = db
      let mut i = 0
      while i < params_list.length() {
        let (affected_rows, updated_db) = current_db.execute(sql, params_list[i])
        current_db = updated_db
        result_mut.push(affected_rows)
        i = i + 1
      }
      // 更新数据库引用
      self.database_ref = Some(current_db)
      result_mut
    }
    None => {
      // 使用传统数据源（模拟实现）
      println("  📝 批量更新 SQL: \{sql}")
      println("  📋 批次数量: \{params_list.length()}")
      println("  ⚠️  使用模拟数据源，实际需要使用内存数据库")
      
      // 返回每条语句的影响行数
      let result : Array[Int] = []
      let mut i = 0
      while i < params_list.length() {
        result.push(1)  // 模拟每条语句影响 1 行
        i = i + 1
      }
      result
    }
  }
}

/// 查询单个值（如 COUNT、MAX 等聚合函数）
/// 
/// 参数：
/// - sql: SQL 语句
/// - params: 参数数组
/// 
/// 返回值：
/// - Some(值): 查询成功
/// - None: 未找到记录
pub fn JdbcTemplate::query_for_scalar(
  self : JdbcTemplate,
  sql : String,
  params : Array[String]
) -> String? {
  // 检查是否使用内存数据库
  match self.database_ref {
    Some(db) => {
      // 使用内存数据库查询
      let rows = db.query(sql, params)
      if rows.length() > 0 {
        // 获取第一行第一列的值（简化实现）
        let first_row = rows[0]
        // 简化实现：返回第一个找到的值
        let mut first_value : String? = None
        first_row.iter().each(fn(entry) {
          let (_key, value) = entry
          match first_value {
            None => first_value = Some(value)
            Some(_) => ()
          }
        })
        first_value
      } else {
        None
      }
    }
    None => {
      // 使用传统数据源（模拟实现）
      println("  📝 查询标量 SQL: \{sql}")
      println("  📋 参数: \{params.length()} 个")
      println("  ⚠️  使用模拟数据源，实际需要使用内存数据库")
      Some("42")  // 模拟返回值
    }
  }
}
