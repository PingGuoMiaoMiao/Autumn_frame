/// Controller - MVC 控制器
/// 
/// 支持基于路径和方法的请求处理

// ========== 导入依赖 ==========

///|
/// Controller 处理器函数类型
pub type ControllerHandler = (@Http.HttpRequest) -> @Http.HttpResponse

///|
/// Controller 方法映射
pub struct ControllerMethod {
  http_method : @Http.HttpMethod // HTTP 方法（GET, POST 等）
  path : String // URL 路径（如：/users/{id}）
  handler : ControllerHandler // 处理函数
}

///|
/// 创建 Controller 方法
pub fn ControllerMethod::new(
  http_method : @Http.HttpMethod,
  path : String,
  handler : ControllerHandler,
) -> ControllerMethod {
  { http_method, path, handler }
}

///|
/// 获取 HTTP 方法
pub fn ControllerMethod::get_http_method(
  self : ControllerMethod,
) -> @Http.HttpMethod {
  self.http_method
}

///|
/// 获取路径
pub fn ControllerMethod::get_path(self : ControllerMethod) -> String {
  self.path
}

///|
/// Controller 定义
pub struct Controller {
  base_path : String // Controller 的基础路径（如：/users）
  methods : Array[ControllerMethod] // 方法列表
}

///|
/// 创建 Controller
pub fn Controller::new(base_path : String) -> Controller {
  { base_path, methods: [] }
}

///|
/// 添加 GET 方法
pub fn Controller::get(
  self : Controller,
  path : String,
  handler : ControllerHandler,
) -> Controller {
  let http_method = @Http.HttpMethod::from_string("GET")
  let controller_method = ControllerMethod::new(http_method, path, handler)
  let methods_mut = self.methods
  methods_mut.push(controller_method)
  { ..self, methods: methods_mut }
}

///|
/// 添加 POST 方法
pub fn Controller::post(
  self : Controller,
  path : String,
  handler : ControllerHandler,
) -> Controller {
  let http_method = @Http.HttpMethod::from_string("POST")
  let controller_method = ControllerMethod::new(http_method, path, handler)
  let methods_mut = self.methods
  methods_mut.push(controller_method)
  { ..self, methods: methods_mut }
}

///|
/// 添加 PUT 方法
pub fn Controller::put(
  self : Controller,
  path : String,
  handler : ControllerHandler,
) -> Controller {
  let http_method = @Http.HttpMethod::from_string("PUT")
  let controller_method = ControllerMethod::new(http_method, path, handler)
  let methods_mut = self.methods
  methods_mut.push(controller_method)
  { ..self, methods: methods_mut }
}

///|
/// 添加 DELETE 方法
pub fn Controller::delete(
  self : Controller,
  path : String,
  handler : ControllerHandler,
) -> Controller {
  let http_method = @Http.HttpMethod::from_string("DELETE")
  let controller_method = ControllerMethod::new(http_method, path, handler)
  let methods_mut = self.methods
  methods_mut.push(controller_method)
  { ..self, methods: methods_mut }
}

///|
/// 获取基础路径
pub fn Controller::get_base_path(self : Controller) -> String {
  self.base_path
}

///|
/// 获取方法列表
pub fn Controller::get_methods(self : Controller) -> Array[ControllerMethod] {
  self.methods
}

///|
/// 查找匹配的方法
/// 
/// 参数：
/// - http_method: HTTP 方法
/// - path: 请求路径（不包含 base_path）
/// 
/// 返回值：
/// - Some(handler): 找到匹配的方法
/// - None: 未找到匹配的方法
pub fn Controller::find_handler(
  self : Controller,
  http_method : @Http.HttpMethod,
  path : String,
) -> ControllerHandler? {
  let mut matched_handler : ControllerHandler? = None
  let mut i = 0
  while i < self.methods.length() {
    let controller_method = self.methods[i]

    // 检查 HTTP 方法是否匹配
    if controller_method.get_http_method() == http_method {
      // 检查路径是否匹配（支持 {id} 占位符）
      if match_path(controller_method.get_path(), path) {
        matched_handler = Some(controller_method.handler)
        break
      }
    }
    i = i + 1
  }
  matched_handler
}

///|
/// 路径匹配（支持简单通配符和占位符）
/// 
/// 例如：
/// - "/users/{id}" 匹配 "/users/123"
/// - "/users" 匹配 "/users"
fn match_path(pattern : String, path : String) -> Bool {
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
