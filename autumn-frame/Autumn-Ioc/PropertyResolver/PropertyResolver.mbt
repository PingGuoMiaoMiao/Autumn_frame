/// PropertyResolver - 配置属性解析器
/// 
/// 功能：
/// 1. 存储和查询配置项（key-value）
/// 2. 支持 ${key} 形式的查询
/// 3. 支持 ${key:defaultValue} 带默认值的查询
/// 4. 支持嵌套查询，如 ${app.title:${APP_NAME:Summer}}
/// 5. 支持类型转换（String, Int, Bool, Double 等）
///
/// 注意：不支持组合表达式（如 jdbc:mysql://${HOST}:${PORT}/${DB}）
///      不支持 #{...} 表达式

/// PropertyExpr - 解析后的属性表达式
priv struct PropertyExpr {
  key : String           // 属性键
  default_value : String? // 默认值（可选）
}

/// PropertyResolver - 配置解析器
pub struct PropertyResolver {
  properties : @hashmap.HashMap[String, String] // 存储所有配置项
  converters : @hashmap.HashMap[String, (String) -> String] // 类型转换器（暂时都返回 String）
}

/// 创建 PropertyResolver
/// properties: 配置项的 Map
pub fn PropertyResolver::new(properties : @hashmap.HashMap[String, String]) -> PropertyResolver {
  let resolver = { 
    properties, 
    converters: @hashmap.new()
  }
  
  // 注册默认的类型转换器
  resolver.register_default_converters()
  resolver
}

/// 从键值对数组创建
pub fn PropertyResolver::from_array(pairs : Array[(String, String)]) -> PropertyResolver {
  let map = @hashmap.new()
  for i = 0; i < pairs.length(); i = i + 1 {
    let (k, v) = pairs[i]
    map.set(k, v)
  }
  PropertyResolver::new(map)
}

/// 注册默认类型转换器
fn PropertyResolver::register_default_converters(self : PropertyResolver) -> Unit {
  // String 类型（直接返回）
  self.converters.set("String", fn(s) { s })
  
  // Int 类型
  self.converters.set("Int", fn(s) { s }) // Moonbit 会自动处理
  
  // Bool 类型
  self.converters.set("Bool", fn(s) { 
    if s == "true" || s == "True" || s == "TRUE" { "true" }
    else if s == "false" || s == "False" || s == "FALSE" { "false" }
    else { s }
  })
  
  // Double 类型
  self.converters.set("Double", fn(s) { s })
}

/// 注册自定义类型转换器
pub fn PropertyResolver::register_converter(
  self : PropertyResolver,
  type_name : String,
  converter : (String) -> String
) -> Unit {
  self.converters.set(type_name, converter)
}

/// 获取属性值（返回 String?）
/// 支持三种形式：
/// 1. 普通 key: "app.title"
/// 2. ${key} 形式: "${app.title}"
/// 3. ${key:default} 形式: "${app.title:Summer}"
pub fn PropertyResolver::get_property(self : PropertyResolver, key : String) -> String? {
  // 解析 ${...} 表达式
  match parse_property_expr(key) {
    Some(expr) => {
      match expr.default_value {
        Some(default) => {
          // 带默认值查询: ${key:default}
          match self.get_property(expr.key) {
            Some(v) => Some(v)
            None => Some(default)
          }
        }
        None => {
          // 不带默认值查询: ${key}
          self.get_required_property(expr.key)
        }
      }
    }
    None => {
      // 普通 key 查询
      match self.properties.get(key) {
        Some(value) => self.parse_value(value)
        None => None
      }
    }
  }
}

/// 获取必需的属性值（不存在则抛出错误）
pub fn PropertyResolver::get_required_property(self : PropertyResolver, key : String) -> String? {
  match self.properties.get(key) {
    Some(value) => self.parse_value(value)
    None => {
      println("Error: Required property '" + key + "' not found")
      None
    }
  }
}

/// 获取属性值并指定默认值
pub fn PropertyResolver::get_property_or_default(
  self : PropertyResolver, 
  key : String, 
  default : String
) -> String {
  match self.get_property(key) {
    Some(v) => v
    None => default
  }
}

/// 获取 Int 类型属性
pub fn PropertyResolver::get_property_int(self : PropertyResolver, key : String) -> Int? {
  match self.get_property(key) {
    Some(v) => {
      // 手动解析整数
      match parse_int_manual(v) {
        Some(i) => Some(i)
        None => {
          println("Error: Cannot convert '" + v + "' to Int")
          None
        }
      }
    }
    None => None
  }
}

/// 获取 Bool 类型属性
pub fn PropertyResolver::get_property_bool(self : PropertyResolver, key : String) -> Bool? {
  match self.get_property(key) {
    Some(v) => {
      let lower = to_lower(v)
      if lower == "true" || lower == "1" || lower == "yes" {
        Some(true)
      } else if lower == "false" || lower == "0" || lower == "no" {
        Some(false)
      } else {
        println("Error: Cannot convert '" + v + "' to Bool")
        None
      }
    }
    None => None
  }
}

/// 获取 Double 类型属性
pub fn PropertyResolver::get_property_double(self : PropertyResolver, key : String) -> Double? {
  match self.get_property(key) {
    Some(v) => {
      match parse_double_manual(v) {
        Some(d) => Some(d)
        None => {
          println("Error: Cannot convert '" + v + "' to Double")
          None
        }
      }
    }
    None => None
  }
}

/// 递归解析值中的 ${...} 表达式
fn PropertyResolver::parse_value(self : PropertyResolver, value : String) -> String? {
  // 检查是否包含 ${...} 表达式
  if value.has_prefix("${") && value.has_suffix("}") {
    // 递归解析嵌套表达式
    self.get_property(value)
  } else {
    Some(value)
  }
}

/// 解析 ${key} 或 ${key:default} 表达式
fn parse_property_expr(key : String) -> PropertyExpr? {
  if key.has_prefix("${") && key.has_suffix("}") {
    let len = key.length()
    
    // 提取 ${...} 中的内容
    let content = try {
      key[2:len - 1].to_string()
    } catch {
      _ => return None
    }
    
    // 查找 : 分隔符
    match index_of(content, ':') {
      Some(colon_pos) => {
        // 有默认值: ${key:default}
        let k = try {
          content[0:colon_pos].to_string()
        } catch {
          _ => return None
        }
        
        let default_val = try {
          content[colon_pos + 1:content.length()].to_string()
        } catch {
          _ => return None
        }
        
        Some({ key: k, default_value: Some(default_val) })
      }
      None => {
        // 没有默认值: ${key}
        Some({ key: content, default_value: None })
      }
    }
  } else {
    None
  }
}

/// 查找字符在字符串中的位置
fn index_of(s : String, ch : Char) -> Int? {
  for i = 0; i < s.length(); i = i + 1 {
    if s[i].unsafe_to_char() == ch {
      return Some(i)
    }
  }
  None
}

/// 手动解析整数
fn parse_int_manual(s : String) -> Int? {
  if s.length() == 0 {
    return None
  }
  
  let mut result = 0
  let mut negative = false
  let mut start = 0
  
  // 检查负号
  if s[0].unsafe_to_char() == '-' {
    negative = true
    start = 1
  } else if s[0].unsafe_to_char() == '+' {
    start = 1
  }
  
  if start >= s.length() {
    return None
  }
  
  for i = start; i < s.length(); i = i + 1 {
    let c = s[i].unsafe_to_char()
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
    } else {
      return None // 非数字字符
    }
  }
  
  Some(if negative { -result } else { result })
}

/// 手动解析浮点数
fn parse_double_manual(s : String) -> Double? {
  if s.length() == 0 {
    return None
  }
  
  let mut result = 0.0
  let mut negative = false
  let mut start = 0
  let mut decimal_point = -1
  
  // 检查负号
  if s[0].unsafe_to_char() == '-' {
    negative = true
    start = 1
  } else if s[0].unsafe_to_char() == '+' {
    start = 1
  }
  
  if start >= s.length() {
    return None
  }
  
  // 查找小数点
  for i = start; i < s.length(); i = i + 1 {
    if s[i].unsafe_to_char() == '.' {
      decimal_point = i
      break
    }
  }
  
  // 解析整数部分
  let end_int = if decimal_point >= 0 { decimal_point } else { s.length() }
  for i = start; i < end_int; i = i + 1 {
    let c = s[i].unsafe_to_char()
    if c >= '0' && c <= '9' {
      result = result * 10.0 + (c.to_int() - '0'.to_int()).to_double()
    } else {
      return None
    }
  }
  
  // 解析小数部分
  if decimal_point >= 0 {
    let mut divisor = 10.0
    for i = decimal_point + 1; i < s.length(); i = i + 1 {
      let c = s[i].unsafe_to_char()
      if c >= '0' && c <= '9' {
        result = result + (c.to_int() - '0'.to_int()).to_double() / divisor
        divisor = divisor * 10.0
      } else {
        return None
      }
    }
  }
  
  Some(if negative { -result } else { result })
}

/// 字符串转小写
fn to_lower(s : String) -> String {
  let mut result = ""
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].unsafe_to_char()
    if c >= 'A' && c <= 'Z' {
      result = result + (c.to_int() + ('a'.to_int() - 'A'.to_int())).unsafe_to_char().to_string()
    } else {
      result = result + c.to_string()
    }
  }
  result
}

/// 检查是否包含某个 key
pub fn PropertyResolver::contains_property(self : PropertyResolver, key : String) -> Bool {
  match self.properties.get(key) {
    Some(_) => true
    None => false
  }
}

/// 获取所有属性的 key 列表
pub fn PropertyResolver::get_property_names(self : PropertyResolver) -> Array[String] {
  let names = []
  self.properties.iter().each(fn(entry) {
    let (k, _) = entry
    names.push(k)
  })
  names
}

/// 设置属性
pub fn PropertyResolver::set_property(self : PropertyResolver, key : String, value : String) -> Unit {
  self.properties.set(key, value)
}

// ========== 测试 ==========

test "PropertyResolver 基本查询" {
  let resolver = PropertyResolver::from_array([
    ("app.name", "Autumn Framework"),
    ("app.version", "1.0"),
    ("debug", "true")
  ])
  
  // 测试基本查询
  match resolver.get_property("app.name") {
    Some(v) => if v != "Autumn Framework" {
      abort("get_property failed")
    }
    None => abort("app.name not found")
  }
  
  match resolver.get_property("app.version") {
    Some(v) => if v != "1.0" {
      abort("version check failed")
    }
    None => abort("app.version not found")
  }
}

test "PropertyResolver ${key} 查询" {
  let resolver = PropertyResolver::from_array([
    ("app.title", "Summer"),
    ("app.version", "2.0")
  ])
  
  // 测试 ${key} 形式
  match resolver.get_property("${app.title}") {
    Some(v) => if v != "Summer" {
      abort("${key} query failed")
    }
    None => abort("${app.title} not found")
  }
}

test "PropertyResolver ${key:default} 查询" {
  let resolver = PropertyResolver::from_array([
    ("app.name", "MyApp")
  ])
  
  // 测试存在的 key
  match resolver.get_property("${app.name:DefaultApp}") {
    Some(v) => if v != "MyApp" {
      abort("${key:default} with existing key failed")
    }
    None => abort("should return value")
  }
  
  // 测试不存在的 key（应返回默认值）
  match resolver.get_property("${app.missing:DefaultValue}") {
    Some(v) => if v != "DefaultValue" {
      abort("${key:default} with missing key failed: got " + v)
    }
    None => abort("should return default value")
  }
}

test "PropertyResolver 嵌套查询" {
  let resolver = PropertyResolver::from_array([
    ("APP_NAME", "Production"),
    ("app.title", "${APP_NAME}")
  ])
  
  // 测试嵌套
  match resolver.get_property("app.title") {
    Some(v) => if v != "Production" {
      abort("nested query failed: got " + v)
    }
    None => abort("nested query returned None")
  }
}

test "PropertyResolver 类型转换" {
  let resolver = PropertyResolver::from_array([
    ("server.port", "8080"),
    ("debug.enabled", "true"),
    ("ratio", "3.14")
  ])
  
  // Int 转换
  match resolver.get_property_int("server.port") {
    Some(port) => if port != 8080 {
      abort("int conversion failed")
    }
    None => abort("should convert to int")
  }
  
  // Bool 转换
  match resolver.get_property_bool("debug.enabled") {
    Some(enabled) => if not(enabled) {
      abort("bool conversion failed")
    }
    None => abort("should convert to bool")
  }
  
  // Double 转换
  match resolver.get_property_double("ratio") {
    Some(r) => if r < 3.13 || r > 3.15 {
      abort("double conversion failed")
    }
    None => abort("should convert to double")
  }
}

test "PropertyResolver contains_property" {
  let resolver = PropertyResolver::from_array([
    ("key1", "value1")
  ])
  
  if not(resolver.contains_property("key1")) {
    abort("contains_property failed for existing key")
  }
  
  if resolver.contains_property("key2") {
    abort("contains_property failed for missing key")
  }
} 