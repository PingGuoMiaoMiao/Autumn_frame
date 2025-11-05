/// ExceptionHandler - 异常处理器
/// 
/// 统一处理应用程序中的异常，提供友好的错误响应
/// 
/// 使用示例：
/// ```moonbit
/// let exception_handler = ExceptionHandler::new()
///   .register_handler("NotFoundException", handle_not_found)
///   .register_handler("ValidationException", handle_validation_error)
/// 
/// dispatcher.set_exception_handler(exception_handler)
/// ```

// ========== 导入依赖 ==========

// ========== 异常类型 ==========

/// 应用程序异常
pub enum ApplicationException {
  /// 未找到资源异常
  NotFoundException(String)
  /// 验证失败异常
  ValidationException(String)
  /// 未授权异常
  UnauthorizedException(String)
  /// 禁止访问异常
  ForbiddenException(String)
  /// 内部服务器错误异常
  InternalServerErrorException(String)
  /// 自定义异常
  CustomException(String, String)  // (异常类型, 异常消息)
}

/// 获取异常消息
pub fn ApplicationException::get_message(self : ApplicationException) -> String {
  match self {
    NotFoundException(msg) => msg
    ValidationException(msg) => msg
    UnauthorizedException(msg) => msg
    ForbiddenException(msg) => msg
    InternalServerErrorException(msg) => msg
    CustomException(_type, msg) => msg
  }
}

/// 获取异常类型
pub fn ApplicationException::get_type(self : ApplicationException) -> String {
  match self {
    NotFoundException(_) => "NotFoundException"
    ValidationException(_) => "ValidationException"
    UnauthorizedException(_) => "UnauthorizedException"
    ForbiddenException(_) => "ForbiddenException"
    InternalServerErrorException(_) => "InternalServerErrorException"
    CustomException(type_name, _) => type_name
  }
}

// ========== 异常处理器接口 ==========

/// 异常处理器函数类型
/// 
/// 参数：
/// - exception: 应用程序异常
/// - request: HTTP 请求
/// 
/// 返回值：
/// - HTTP 响应
pub type ExceptionHandlerFunc = (ApplicationException, @Http.HttpRequest) -> @Http.HttpResponse

// ========== 异常处理器 ==========

/// 异常处理器
/// 
/// 用于注册和处理不同类型的异常
pub struct ExceptionHandler {
  handlers : @hashmap.HashMap[String, ExceptionHandlerFunc]  // 异常类型 -> 处理器函数
  default_handler : ExceptionHandlerFunc?  // 默认处理器（可选）
}

/// 创建异常处理器
pub fn ExceptionHandler::new() -> ExceptionHandler {
  {
    handlers: @hashmap.new(),
    default_handler: None
  }
}

/// 注册异常处理器
pub fn ExceptionHandler::register_handler(
  self : ExceptionHandler,
  exception_type : String,
  handler : ExceptionHandlerFunc
) -> ExceptionHandler {
  self.handlers.set(exception_type, handler)
  self
}

/// 设置默认异常处理器
pub fn ExceptionHandler::set_default_handler(
  self : ExceptionHandler,
  handler : ExceptionHandlerFunc
) -> ExceptionHandler {
  { ..self, default_handler: Some(handler) }
}

/// 处理异常
/// 
/// 参数：
/// - exception: 应用程序异常
/// - request: HTTP 请求
/// 
/// 返回值：
/// - HTTP 响应
pub fn ExceptionHandler::handle_exception(
  self : ExceptionHandler,
  exception : ApplicationException,
  request : @Http.HttpRequest
) -> @Http.HttpResponse {
  let exception_type = exception.get_type()
  
  // 查找对应的处理器
  match self.handlers.get(exception_type) {
    Some(handler) => {
      // 使用注册的处理器
      handler(exception, request)
    }
    None => {
      // 使用默认处理器
      match self.default_handler {
        Some(default_handler) => {
          default_handler(exception, request)
        }
        None => {
          // 如果没有默认处理器，返回通用错误响应
          handle_exception_default(exception, request)
        }
      }
    }
  }
}

/// 将 HashMap 转换为 JSON 字符串
fn hashmap_to_json(data : @hashmap.HashMap[String, String]) -> String {
  let mut json_str = "{"
  let mut first = true
  
  data.iter().each(fn(entry) {
    let (key, value) = entry
    if first {
      json_str = json_str + "\"" + key + "\":\"" + value + "\""
      first = false
    } else {
      json_str = json_str + ",\"" + key + "\":\"" + value + "\""
    }
  })
  
  json_str = json_str + "}"
  json_str
}

/// 默认异常处理函数
/// 
/// 根据异常类型返回相应的 HTTP 响应
fn handle_exception_default(
  exception : ApplicationException,
  _request : @Http.HttpRequest
) -> @Http.HttpResponse {
  match exception {
    NotFoundException(msg) => {
      let body = @hashmap.new()
      body.set("error", "Not Found")
      body.set("message", msg)
      let json_str = hashmap_to_json(body)
      @Http.HttpResponse::not_found(Some(json_str))
    }
    ValidationException(msg) => {
      let body = @hashmap.new()
      body.set("error", "Validation Error")
      body.set("message", msg)
      let json_str = hashmap_to_json(body)
      @Http.HttpResponse::new(400, @hashmap.new(), Some(json_str))
    }
    UnauthorizedException(msg) => {
      let body = @hashmap.new()
      body.set("error", "Unauthorized")
      body.set("message", msg)
      let json_str = hashmap_to_json(body)
      @Http.HttpResponse::new(401, @hashmap.new(), Some(json_str))
    }
    ForbiddenException(msg) => {
      let body = @hashmap.new()
      body.set("error", "Forbidden")
      body.set("message", msg)
      let json_str = hashmap_to_json(body)
      @Http.HttpResponse::new(403, @hashmap.new(), Some(json_str))
    }
    InternalServerErrorException(msg) => {
      let body = @hashmap.new()
      body.set("error", "Internal Server Error")
      body.set("message", msg)
      let json_str = hashmap_to_json(body)
      @Http.HttpResponse::internal_server_error(Some(json_str))
    }
    CustomException(type_name, msg) => {
      let body = @hashmap.new()
      body.set("error", type_name)
      body.set("message", msg)
      let json_str = hashmap_to_json(body)
      @Http.HttpResponse::internal_server_error(Some(json_str))
    }
  }
}

/// 创建标准异常处理器
/// 
/// 返回一个预配置的异常处理器，包含常见异常类型的处理
pub fn ExceptionHandler::create_default() -> ExceptionHandler {
  let handler = ExceptionHandler::new()
    .register_handler("NotFoundException", fn(exception, _request) {
      let body = @hashmap.new()
      body.set("error", "Not Found")
      body.set("message", exception.get_message())
      let json_str = hashmap_to_json(body)
      @Http.HttpResponse::not_found(Some(json_str))
    })
    .register_handler("ValidationException", fn(exception, _request) {
      let body = @hashmap.new()
      body.set("error", "Validation Error")
      body.set("message", exception.get_message())
      let json_str = hashmap_to_json(body)
      @Http.HttpResponse::new(400, @hashmap.new(), Some(json_str))
    })
    .register_handler("UnauthorizedException", fn(exception, _request) {
      let body = @hashmap.new()
      body.set("error", "Unauthorized")
      body.set("message", exception.get_message())
      let json_str = hashmap_to_json(body)
      @Http.HttpResponse::new(401, @hashmap.new(), Some(json_str))
    })
    .register_handler("ForbiddenException", fn(exception, _request) {
      let body = @hashmap.new()
      body.set("error", "Forbidden")
      body.set("message", exception.get_message())
      let json_str = hashmap_to_json(body)
      @Http.HttpResponse::new(403, @hashmap.new(), Some(json_str))
    })
    .register_handler("InternalServerErrorException", fn(exception, _request) {
      let body = @hashmap.new()
      body.set("error", "Internal Server Error")
      body.set("message", exception.get_message())
      let json_str = hashmap_to_json(body)
      @Http.HttpResponse::internal_server_error(Some(json_str))
    })
  
  handler
}

