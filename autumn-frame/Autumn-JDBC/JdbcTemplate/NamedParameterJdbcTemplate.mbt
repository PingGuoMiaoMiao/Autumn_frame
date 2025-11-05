/// NamedParameterJdbcTemplate - 支持命名参数的 JDBC 模板
/// 
/// 将命名参数（:name）转换为位置参数（?），然后调用 JdbcTemplate
/// 
/// 使用示例：
/// ```moonbit
/// let jdbc_template = JdbcTemplate::new_with_memory_database(database)
/// let named_template = NamedParameterJdbcTemplate::new(jdbc_template)
/// 
/// let params = @hashmap.new()
/// params.set("name", "Alice")
/// params.set("age", "25")
/// 
/// let rows = named_template.update(
///   "INSERT INTO users (name, age) VALUES (:name, :age)",
///   params
/// )
/// ```

/// NamedParameterJdbcTemplate 结构
pub struct NamedParameterJdbcTemplate {
  jdbc_template : JdbcTemplate  // 底层的 JdbcTemplate
}

/// 创建 NamedParameterJdbcTemplate
pub fn NamedParameterJdbcTemplate::new(jdbc_template : JdbcTemplate) -> NamedParameterJdbcTemplate {
  { jdbc_template, }
}

// ========== 参数解析和转换 ==========

/// 解析命名参数 SQL
/// 
/// 将 SQL 中的命名参数（:name）替换为位置参数（?）
/// 同时提取参数名称和值的对应关系
/// 
/// 参数：
/// - sql: 包含命名参数的 SQL 语句（如：":name, :age"）
/// - params: 命名参数映射（key -> value）
/// 
/// 返回值：
/// - (converted_sql, param_values): 转换后的 SQL 和参数值数组
fn parse_named_parameters(
  sql : String,
  params : @hashmap.HashMap[String, String]
) -> (String, Array[String]) {
  let mut converted_sql = ""
  let param_values : Array[String] = []
  let param_values_mut = param_values
  let mut i = 0
  let sql_len = sql.length()
  
  while i < sql_len {
    let c = sql[i].unsafe_to_char()
    
    if c == ':' && i + 1 < sql_len {
      // 找到命名参数开始
      let mut param_name = ""
      let mut j = i + 1
      
      // 提取参数名（字母、数字、下划线）
      while j < sql_len {
        let next_c = sql[j].unsafe_to_char()
        if (next_c >= 'a' && next_c <= 'z') || 
           (next_c >= 'A' && next_c <= 'Z') ||
           (next_c >= '0' && next_c <= '9') ||
           next_c == '_' {
          param_name = param_name + next_c.to_string()
          j = j + 1
        } else {
          break
        }
      }
      
      // 查找参数值
      match params.get(param_name) {
        Some(value) => {
          converted_sql = converted_sql + "?"
          param_values_mut.push(value)
          i = j
        }
        None => {
          // 参数未找到，保持原样（或抛出错误）
          converted_sql = converted_sql + ":" + param_name
          i = j
        }
      }
    } else {
      converted_sql = converted_sql + c.to_string()
      i = i + 1
    }
  }
  
  (converted_sql, param_values_mut)
}

// ========== 核心方法 ==========

/// 执行 SQL（不返回结果）
/// 
/// 参数：
/// - sql: SQL 语句（支持命名参数 :name）
/// - params: 命名参数映射
/// 
/// 返回值：
/// - 影响的行数
pub fn NamedParameterJdbcTemplate::execute(
  self : NamedParameterJdbcTemplate,
  sql : String,
  params : @hashmap.HashMap[String, String]
) -> Int {
  let (converted_sql, param_values) = parse_named_parameters(sql, params)
  self.jdbc_template.execute(converted_sql, param_values)
}

/// 查询并映射为单个对象
/// 
/// 参数：
/// - sql: SQL 查询语句（支持命名参数）
/// - params: 命名参数映射
/// - row_mapper: 行映射器
/// 
/// 返回值：
/// - Some(对象): 查询成功
/// - None: 未找到记录
pub fn NamedParameterJdbcTemplate::query(
  self : NamedParameterJdbcTemplate,
  sql : String,
  params : @hashmap.HashMap[String, String],
  row_mapper : RowMapper
) -> String? {
  let (converted_sql, param_values) = parse_named_parameters(sql, params)
  self.jdbc_template.query(converted_sql, param_values, row_mapper)
}

/// 查询并映射为列表
/// 
/// 参数：
/// - sql: SQL 查询语句（支持命名参数）
/// - params: 命名参数映射
/// - row_mapper: 行映射器
/// 
/// 返回值：
/// - 对象列表
pub fn NamedParameterJdbcTemplate::query_for_list(
  self : NamedParameterJdbcTemplate,
  sql : String,
  params : @hashmap.HashMap[String, String],
  row_mapper : RowMapper
) -> Array[String] {
  let (converted_sql, param_values) = parse_named_parameters(sql, params)
  self.jdbc_template.query_for_list(converted_sql, param_values, row_mapper)
}

/// 更新操作（INSERT/UPDATE/DELETE）
/// 
/// 参数：
/// - sql: SQL 语句（支持命名参数）
/// - params: 命名参数映射
/// 
/// 返回值：
/// - 影响的行数
pub fn NamedParameterJdbcTemplate::update(
  self : NamedParameterJdbcTemplate,
  sql : String,
  params : @hashmap.HashMap[String, String]
) -> Int {
  let (converted_sql, param_values) = parse_named_parameters(sql, params)
  self.jdbc_template.update(converted_sql, param_values)
}

/// 批量更新
/// 
/// 参数：
/// - sql: SQL 语句（支持命名参数）
/// - params_list: 参数列表数组（每个元素是一个命名参数映射）
/// 
/// 返回值：
/// - 每条语句影响的行数数组
pub fn NamedParameterJdbcTemplate::batch_update(
  self : NamedParameterJdbcTemplate,
  sql : String,
  params_list : Array[@hashmap.HashMap[String, String]]
) -> Array[Int] {
  let results : Array[Int] = []
  let results_mut = results
  let mut i = 0
  while i < params_list.length() {
    let params = params_list[i]
    let (converted_sql, param_values) = parse_named_parameters(sql, params)
    let affected_rows = self.jdbc_template.update(converted_sql, param_values)
    results_mut.push(affected_rows)
    i = i + 1
  }
  results_mut
}

/// 查询单个值（如 COUNT、MAX 等聚合函数）
/// 
/// 参数：
/// - sql: SQL 语句（支持命名参数）
/// - params: 命名参数映射
/// 
/// 返回值：
/// - Some(值): 查询成功
/// - None: 未找到记录
pub fn NamedParameterJdbcTemplate::query_for_scalar(
  self : NamedParameterJdbcTemplate,
  sql : String,
  params : @hashmap.HashMap[String, String]
) -> String? {
  let (converted_sql, param_values) = parse_named_parameters(sql, params)
  self.jdbc_template.query_for_scalar(converted_sql, param_values)
}

