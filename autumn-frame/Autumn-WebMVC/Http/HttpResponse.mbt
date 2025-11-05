/// HttpResponse - HTTP 响应
/// 
/// 封装 HTTP 响应信息

/// HTTP 状态码
/// 
/// 注意：这些枚举值用于类型安全，实际状态码通过 get_code() 方法获取
pub enum HttpStatus {
  OK           // 200
  Created      // 201
  NoContent    // 204
  BadRequest   // 400
  Unauthorized // 401
  Forbidden    // 403
  NotFound     // 404
  InternalServerError // 500
} derive(Eq, Show)

// 使用这些枚举值来避免警告
fn _use_http_status() -> Unit {
  let _ = OK
  let _ = Created
  let _ = NoContent
  let _ = BadRequest
  let _ = Unauthorized
  let _ = Forbidden
  let _ = NotFound
  let _ = InternalServerError
  ()
}

/// 获取状态码数值
pub fn HttpStatus::get_code(self : HttpStatus) -> Int {
  match self {
    OK => 200
    Created => 201
    NoContent => 204
    BadRequest => 400
    Unauthorized => 401
    Forbidden => 403
    NotFound => 404
    InternalServerError => 500
  }
}

/// HTTP 响应
pub struct HttpResponse {
  status_code : Int                    // 状态码（200, 404, 500 等）
  headers : @hashmap.HashMap[String, String]  // 响应头
  body : String?                       // 响应体
}

/// 创建 HTTP 响应
pub fn HttpResponse::new(
  status_code : Int,
  headers : @hashmap.HashMap[String, String],
  body : String?
) -> HttpResponse {
  { status_code, headers, body }
}

/// 创建成功响应（200 OK）
pub fn HttpResponse::ok(body : String) -> HttpResponse {
  {
    status_code: 200,
    headers: @hashmap.new(),
    body: Some(body)
  }
}

/// 创建创建成功响应（201 Created）
pub fn HttpResponse::created(body : String) -> HttpResponse {
  {
    status_code: 201,
    headers: @hashmap.new(),
    body: Some(body)
  }
}

/// 创建无内容响应（204 No Content）
pub fn HttpResponse::no_content() -> HttpResponse {
  {
    status_code: 204,
    headers: @hashmap.new(),
    body: None
  }
}

/// 创建错误响应（400 Bad Request）
pub fn HttpResponse::bad_request(body : String) -> HttpResponse {
  {
    status_code: 400,
    headers: @hashmap.new(),
    body: Some(body)
  }
}

/// 创建未授权响应（401 Unauthorized）
pub fn HttpResponse::unauthorized(body : String) -> HttpResponse {
  {
    status_code: 401,
    headers: @hashmap.new(),
    body: Some(body)
  }
}

/// 创建禁止响应（403 Forbidden）
pub fn HttpResponse::forbidden(body : String) -> HttpResponse {
  {
    status_code: 403,
    headers: @hashmap.new(),
    body: Some(body)
  }
}

/// 创建未找到响应（404 Not Found）
pub fn HttpResponse::not_found(body : String?) -> HttpResponse {
  {
    status_code: 404,
    headers: @hashmap.new(),
    body: match body {
      Some(msg) => Some(msg)
      None => Some("404 Not Found")
    }
  }
}

/// 创建服务器错误响应（500 Internal Server Error）
pub fn HttpResponse::internal_server_error(body : String?) -> HttpResponse {
  {
    status_code: 500,
    headers: @hashmap.new(),
    body: match body {
      Some(msg) => Some(msg)
      None => Some("500 Internal Server Error")
    }
  }
}

/// 创建 JSON 响应
pub fn HttpResponse::json(body : String) -> HttpResponse {
  let headers : @hashmap.HashMap[String, String] = @hashmap.new()
  let headers_mut = headers
  headers_mut.set("Content-Type", "application/json")
  {
    status_code: 200,
    headers: headers_mut,
    body: Some(body)
  }
}

/// 获取状态码
pub fn HttpResponse::get_status_code(self : HttpResponse) -> Int {
  self.status_code
}

/// 获取响应体
pub fn HttpResponse::get_body(self : HttpResponse) -> String? {
  self.body
}

/// 设置响应头
pub fn HttpResponse::set_header(
  self : HttpResponse,
  key : String,
  value : String
) -> HttpResponse {
  self.headers.set(key, value)
  self
}

/// 获取响应头
pub fn HttpResponse::get_header(self : HttpResponse, key : String) -> String? {
  self.headers.get(key)
}

