/// RestController - REST 控制器
/// 
/// 支持 RESTful API 的请求处理，返回 JSON 格式

// ========== 导入依赖 ==========

/// JSON 数据（使用 HashMap 表示）
pub type JsonData = @hashmap.HashMap[String, String]

/// JSON 响应
pub struct JsonResponse {
  data : JsonData  // JSON 数据（简化实现：使用 HashMap）
}

/// 创建 JSON 响应
pub fn JsonResponse::new(data : JsonData) -> JsonResponse {
  { data, }
}

/// 转换为 HTTP 响应
pub fn JsonResponse::to_http_response(self : JsonResponse) -> @Http.HttpResponse {
  // 简化实现：将 HashMap 转换为 JSON 字符串
  let mut json_str = "{"
  let mut first = true
  
  self.data.iter().each(fn(entry) {
    let (key, value) = entry
    if first {
      json_str = json_str + "\"" + key + "\":\"" + value + "\""
      first = false
    } else {
      json_str = json_str + ",\"" + key + "\":\"" + value + "\""
    }
  })
  
  json_str = json_str + "}"
  
  @Http.HttpResponse::json(json_str)
}

/// RestController 处理器函数类型
pub type RestControllerHandler = (@Http.HttpRequest) -> JsonResponse

/// RestController 方法映射
pub struct RestControllerMethod {
  http_method : @Http.HttpMethod
  path : String
  handler : RestControllerHandler
}

/// 创建 RestController 方法
pub fn RestControllerMethod::new(
  http_method : @Http.HttpMethod,
  path : String,
  handler : RestControllerHandler
) -> RestControllerMethod {
  { http_method, path, handler }
}

/// 获取 HTTP 方法
pub fn RestControllerMethod::get_http_method(self : RestControllerMethod) -> @Http.HttpMethod {
  self.http_method
}

/// 获取路径
pub fn RestControllerMethod::get_path(self : RestControllerMethod) -> String {
  self.path
}

/// RestController 定义
pub struct RestController {
  base_path : String
  methods : Array[RestControllerMethod]
}

/// 创建 RestController
pub fn RestController::new(base_path : String) -> RestController {
  { base_path, methods: [] }
}

/// 添加 GET 方法
pub fn RestController::get(
  self : RestController,
  path : String,
  handler : RestControllerHandler
) -> RestController {
  let http_method = @Http.HttpMethod::from_string("GET")
  let rest_method = RestControllerMethod::new(http_method, path, handler)
  let methods_mut = self.methods
  methods_mut.push(rest_method)
  { ..self, methods: methods_mut }
}

/// 添加 POST 方法
pub fn RestController::post(
  self : RestController,
  path : String,
  handler : RestControllerHandler
) -> RestController {
  let http_method = @Http.HttpMethod::from_string("POST")
  let rest_method = RestControllerMethod::new(http_method, path, handler)
  let methods_mut = self.methods
  methods_mut.push(rest_method)
  { ..self, methods: methods_mut }
}

/// 添加 PUT 方法
pub fn RestController::put(
  self : RestController,
  path : String,
  handler : RestControllerHandler
) -> RestController {
  let http_method = @Http.HttpMethod::from_string("PUT")
  let rest_method = RestControllerMethod::new(http_method, path, handler)
  let methods_mut = self.methods
  methods_mut.push(rest_method)
  { ..self, methods: methods_mut }
}

/// 添加 DELETE 方法
pub fn RestController::delete(
  self : RestController,
  path : String,
  handler : RestControllerHandler
) -> RestController {
  let http_method = @Http.HttpMethod::from_string("DELETE")
  let rest_method = RestControllerMethod::new(http_method, path, handler)
  let methods_mut = self.methods
  methods_mut.push(rest_method)
  { ..self, methods: methods_mut }
}

/// 获取基础路径
pub fn RestController::get_base_path(self : RestController) -> String {
  self.base_path
}

/// 获取方法列表
pub fn RestController::get_methods(self : RestController) -> Array[RestControllerMethod] {
  self.methods
}

/// 查找匹配的方法
/// 
/// 参数：
/// - http_method: HTTP 方法
/// - path: 请求路径（不包含 base_path）
/// 
/// 返回值：
/// - Some(handler): 找到匹配的方法
/// - None: 未找到匹配的方法
pub fn RestController::find_handler(
  self : RestController,
  http_method : @Http.HttpMethod,
  path : String
) -> RestControllerHandler? {
  let mut matched_handler : RestControllerHandler? = None
  
  let mut i = 0
  while i < self.methods.length() {
    let rest_method = self.methods[i]
    
    // 检查 HTTP 方法是否匹配
    if rest_method.get_http_method() == http_method {
      // 检查路径是否匹配（支持 {id} 占位符）
      if match_rest_path(rest_method.get_path(), path) {
        matched_handler = Some(rest_method.handler)
        break
      }
    }
    
    i = i + 1
  }
  
  matched_handler
}

/// 路径匹配（支持简单通配符和占位符）
/// 
/// 例如：
/// - "/users/{id}" 匹配 "/users/123"
/// - "/users" 匹配 "/users"
fn match_rest_path(pattern : String, path : String) -> Bool {
  // 精确匹配
  if pattern == path {
    return true
  }
  
  // 支持 {id} 占位符
  let pattern_parts = Array::from_iter(pattern.split("/"))
  let path_parts = Array::from_iter(path.split("/"))
  
  if pattern_parts.length() != path_parts.length() {
    return false
  }
  
  let mut i = 0
  while i < pattern_parts.length() {
    let pattern_part = pattern_parts[i].to_string()
    let path_part = path_parts[i].to_string()
    
    // {id} 占位符可以匹配任何值
    if pattern_part.has_prefix("{") && pattern_part.has_suffix("}") {
      // 占位符，继续
    } else if pattern_part != path_part {
      return false
    }
    
    i = i + 1
  }
  
  true
}

