/// HttpRequest - HTTP 请求
/// 
/// 封装 HTTP 请求信息

///|
/// HTTP 请求方法
pub enum HttpMethod {
  GET
  POST
  PUT
  DELETE
  PATCH
  HEAD
  OPTIONS
} derive(Eq, Show)

///|
/// HTTP 请求
pub struct HttpRequest {
  http_method : HttpMethod // HTTP 方法
  path : String // 请求路径（如：/users/123）
  query_params : @hashmap.HashMap[String, String] // 查询参数（如：?name=Alice）
  headers : @hashmap.HashMap[String, String] // 请求头
  body : String? // 请求体（POST/PUT 请求）
}

///|
/// 创建 HTTP 请求
pub fn HttpRequest::new(
  http_method : HttpMethod,
  path : String,
  query_params : @hashmap.HashMap[String, String],
  headers : @hashmap.HashMap[String, String],
  body : String?,
) -> HttpRequest {
  { http_method, path, query_params, headers, body }
}

///|
/// 从字符串创建 HTTP 方法
pub fn HttpMethod::from_string(method_str : String) -> HttpMethod {
  match method_str {
    "GET" => GET
    "POST" => POST
    "PUT" => PUT
    "DELETE" => DELETE
    "PATCH" => PATCH
    "HEAD" => HEAD
    "OPTIONS" => OPTIONS
    _ => GET // 默认 GET
  }
}

///|
/// 获取 HTTP 方法
pub fn HttpRequest::get_method(self : HttpRequest) -> HttpMethod {
  self.http_method
}

///|
/// 获取请求路径
pub fn HttpRequest::get_path(self : HttpRequest) -> String {
  self.path
}

///|
/// 获取查询参数
pub fn HttpRequest::get_query_param(
  self : HttpRequest,
  key : String,
) -> String? {
  self.query_params.get(key)
}

///|
/// 获取请求头
pub fn HttpRequest::get_header(self : HttpRequest, key : String) -> String? {
  self.headers.get(key)
}

///|
/// 获取请求体
pub fn HttpRequest::get_body(self : HttpRequest) -> String? {
  self.body
}

///|
/// 解析路径参数（从路径中提取 {id} 等占位符的值）
/// 
/// 例如：路径模式 "/users/{id}" 匹配 "/users/123" 时，返回 {"id": "123"}
pub fn HttpRequest::extract_path_params(
  _self : HttpRequest,
  pattern : String,
  path : String,
) -> @hashmap.HashMap[String, String] {
  let params = @hashmap.new()

  // 简化实现：匹配路径并提取参数
  let pattern_parts = Array::from_iter(pattern.split("/"))
  let path_parts = Array::from_iter(path.split("/"))
  if pattern_parts.length() == path_parts.length() {
    let mut i = 0
    while i < pattern_parts.length() {
      let pattern_part = pattern_parts[i].to_string()
      let path_part = path_parts[i].to_string()

      // 检查是否是占位符 {name}
      if pattern_part.has_prefix("{") && pattern_part.has_suffix("}") {
        // 提取参数名（使用 try-catch 处理可能的错误）
        let param_name = try {
          let start = 1
          let end = pattern_part.length() - 1
          if start < end {
            pattern_part[start:end].to_string()
          } else {
            ""
          }
        } catch {
          _ => ""
        }
        if param_name.length() > 0 {
          params.set(param_name, path_part)
        }
      }
      i = i + 1
    }
  }
  params
}
