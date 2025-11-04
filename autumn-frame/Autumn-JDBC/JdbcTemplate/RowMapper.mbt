/// RowMapper - 行映射器
/// 
/// 将数据库行映射为对象

// ========== 行映射器类型 ==========

/// 数据库行（使用 HashMap 表示）
pub type Row = @hashmap.HashMap[String, String]

/// 行映射器函数类型
/// 
/// 参数：
/// - row: 数据库行（列名 -> 值）
/// 
/// 返回值：
/// - 映射后的对象（使用 String 表示，实际应用中可以是任意类型）
pub type RowMapper = (Row) -> String

/// 简单的行映射器实现
pub fn simple_row_mapper(row : Row) -> String {
  // 将行转换为 JSON 字符串（简化实现）
  let mut result = "{"
  let mut first = true
  row.iter().each(fn(entry) {
    let (key, value) = entry
    if first {
      first = false
    } else {
      result = result + ", "
    }
    result = result + "\"" + key + "\": \"" + value + "\""
  })
  result + "}"
}

/// ID 映射器（提取第一列作为 ID）
pub fn id_mapper(row : Row) -> String {
  let mut first_value : String? = None
  row.iter().each(fn(entry) {
    let (_key, value) = entry
    match first_value {
      None => first_value = Some(value)
      Some(_) => ()
    }
  })
  match first_value {
    Some(value) => value
    None => ""
  }
}

