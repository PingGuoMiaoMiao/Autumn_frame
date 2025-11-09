/// 登录认证模块
/// 
/// 提供登录验证、用户认证等功能

///|
/// 解析表单数据（application/x-www-form-urlencoded）
/// 
/// 例如：username=admin&password=123456
pub fn parse_form_data(body : String) -> @hashmap.HashMap[String, String] {
  let params = @hashmap.new()
  let pairs = Array::from_iter(body.split("&"))
  for i = 0; i < pairs.length(); i = i + 1 {
    let pair = pairs[i].to_string()
    let kv = Array::from_iter(pair.split("="))
    if kv.length() == 2 {
      let key = kv[0].to_string()
      let value = kv[1].to_string()
      // URL 解码（简化实现，实际应该使用 UrlDecoder）
      params.set(key, value)
    }
  }
  params
}

///|
/// 解析 JSON 数据（application/json）
/// 
/// 简化实现：解析简单的 JSON 对象 {"username":"admin","password":"123456"}
pub fn parse_json_data(body : String) -> @hashmap.HashMap[String, String] {
  let params = @hashmap.new()
  // 移除空格和换行
  let cleaned = body.replace(old=" ", new="").replace(old="\n", new="")

  // 移除 { 和 }
  let content = if cleaned.has_prefix("{") && cleaned.has_suffix("}") {
    let len = cleaned.length()
    if len > 2 {
      cleaned[1:len - 1].to_string() catch {
        _ => cleaned
      }
    } else {
      cleaned
    }
  } else {
    cleaned
  }

  // 分割键值对
  let pairs = Array::from_iter(content.split(","))
  for i = 0; i < pairs.length(); i = i + 1 {
    let pair = pairs[i].to_string()
    let kv = Array::from_iter(pair.split(":"))
    if kv.length() == 2 {
      let key_raw = kv[0].to_string()
      let value_raw = kv[1].to_string()

      // 移除引号
      let key = if key_raw.has_prefix("\"") && key_raw.has_suffix("\"") {
        let key_len = key_raw.length()
        if key_len > 2 {
          key_raw[1:key_len - 1].to_string() catch {
            _ => key_raw
          }
        } else {
          key_raw
        }
      } else {
        key_raw
      }
      let value = if value_raw.has_prefix("\"") && value_raw.has_suffix("\"") {
        let val_len = value_raw.length()
        if val_len > 2 {
          value_raw[1:val_len - 1].to_string() catch {
            _ => value_raw
          }
        } else {
          value_raw
        }
      } else {
        value_raw
      }
      params.set(key, value)
    }
  }
  params
}

///|
/// 验证用户登录
/// 
/// 参数：
/// - username: 用户名
/// - password: 密码
/// 
/// 返回值：
/// - true: 登录成功
/// - false: 登录失败
pub fn validate_login(username : String, password : String) -> Bool {
  // 简化实现：硬编码的用户验证
  // 实际项目中应该从数据库查询

  // 测试用户
  if username == "admin" && password == "123456" {
    true
  } else if username == "user" && password == "password" {
    true
  } else {
    false
  }
}

///|
/// 从请求中提取登录信息
/// 
/// 支持两种格式：
/// 1. application/x-www-form-urlencoded: username=admin&password=123456
/// 2. application/json: {"username":"admin","password":"123456"}
pub fn extract_login_info(request : @Http.HttpRequest) -> (String?, String?) {
  match request.get_body() {
    Some(body) => {
      // 检查 Content-Type
      let content_type = match request.get_header("Content-Type") {
        Some(ct) => ct
        None => ""
      }
      let params = if content_type.contains("application/json") {
        parse_json_data(body)
      } else {
        // 默认使用表单格式
        parse_form_data(body)
      }
      let username = params.get("username")
      let password = params.get("password")
      (username, password)
    }
    None => (None, None)
  }
}

///|
/// 登录响应结果
pub struct LoginResult {
  success : Bool // 是否成功
  message : String // 响应消息
  token : String? // 登录令牌（可选）
}

///|
/// 创建成功响应
pub fn LoginResult::success(message : String, token : String?) -> LoginResult {
  { success: true, message, token }
}

///|
/// 创建失败响应
pub fn LoginResult::failure(message : String) -> LoginResult {
  { success: false, message, token: None }
}

///|
/// 处理登录请求
/// 
/// 参数：
/// - request: HTTP 请求
/// 
/// 返回值：
/// - JsonResponse（用于 RestController）
pub fn handle_login(request : @Http.HttpRequest) -> @Controller.JsonResponse {
  // 1. 提取登录信息
  let (username_opt, password_opt) = extract_login_info(request)
  match (username_opt, password_opt) {
    (Some(username), Some(password)) =>
      // 2. 验证登录
      if validate_login(username, password) {
        // 3. 登录成功
        let token = "token_" + username + "_" + password // 简化实现，实际应该生成 JWT
        let result = LoginResult::success("登录成功", Some(token))

        // 返回 JSON 响应
        let data = @hashmap.new()
        data.set("success", "true")
        data.set("message", result.message)
        data.set("token", token)
        @Controller.JsonResponse::new(data)
      } else {
        // 4. 登录失败
        let result = LoginResult::failure("用户名或密码错误")

        // 返回 JSON 响应
        let data = @hashmap.new()
        data.set("success", "false")
        data.set("message", result.message)
        @Controller.JsonResponse::new(data)
      }
    _ => {
      // 5. 缺少参数
      let result = LoginResult::failure("请提供用户名和密码")

      // 返回 JSON 响应
      let data = @hashmap.new()
      data.set("success", "false")
      data.set("message", result.message)
      @Controller.JsonResponse::new(data)
    }
  }
}

///|
/// 处理登出请求
pub fn handle_logout(_request : @Http.HttpRequest) -> @Controller.JsonResponse {
  let data = @hashmap.new()
  data.set("success", "true")
  data.set("message", "登出成功")
  @Controller.JsonResponse::new(data)
}
