/// Autumn Framework 完整示例
/// 
/// 根据使用指南创建的完整示例，展示如何使用 Autumn Frame 构建 Web 应用
/// 类似 Spring Boot 的开发体验

// ========== 导入依赖 ==========

fn parse_request_params(request : @Http.HttpRequest) -> @hashmap.HashMap[String, String]? {
  match request.get_body() {
    Some(body) => {
      let content_type = match request.get_header("Content-Type") {
        Some(ct) => ct
        None => ""
      }
      if content_type.contains("application/json") {
        Some(parse_json_data(body))
      } else {
        Some(parse_form_data(body))
      }
    }
    None => None
  }
}

fn opt_string_or(value : String?, fallback : String) -> String {
  match value {
    Some(v) => v
    None => fallback
  }
}

fn safe_strip_prefix(value : String, prefix : String) -> String {
  if value.has_prefix(prefix) {
    let len = value.length()
    let pre_len = prefix.length()
    if len > pre_len {
      value[pre_len:len].to_string() catch { _ => value }
    } else {
      ""
    }
  } else {
    value
  }
}

fn extract_path_tail(path : String) -> String {
  let parts = Array::from_iter(path.split("/"))
  if parts.length() == 0 {
    path
  } else {
    parts[parts.length() - 1].to_string()
  }
}

fn handle_log_upload(request : @Http.HttpRequest) -> @Controller.JsonResponse {
  match request.get_body() {
    Some(body) => {
      let content_type = match request.get_header("Content-Type") {
        Some(ct) => ct
        None => ""
      }
      
      let params = if content_type.contains("application/json") {
        parse_json_data(body)
      } else {
        // 允许表单格式作为降级方案
        parse_form_data(body)
      }
      
      match (params.get("level"), params.get("message")) {
        (Some(level), Some(message)) => {
          let request_id_opt = request.get_header("X-Request-Id")
          let timestamp = match params.get("timestamp") {
            Some(ts) => ts
            None => ""
          }
          let context = match params.get("context") {
            Some(ctx) => ctx
            None => ""
          }
          let origin = match params.get("origin") {
            Some(or) => or
            None => ""
          }
          let device = match params.get("device") {
            Some(dev) => dev
            None => ""
          }
          
          let request_id = match request_id_opt {
            Some(id) => id
            None => match params.get("logId") {
              Some(user_log_id) => user_log_id
              None => if timestamp != "" {
                "log-" + timestamp
              } else {
                "log-" + level
              }
            }
          }
          
          println("[LOG] id=" + request_id + " level=" + level + " message=" + message)
          if timestamp != "" {
            println("      timestamp=" + timestamp)
          }
          if context != "" {
            println("      context=" + context)
          }
          if origin != "" {
            println("      origin=" + origin)
          }
          if device != "" {
            println("      device=" + device)
          }
          
          let response = @hashmap.new()
          response.set("success", "true")
          response.set("message", "日志已接收")
          response.set("requestId", request_id)
          response.set("level", level)
          response.set("logMessage", message)
          if timestamp != "" {
            response.set("timestamp", timestamp)
          }
          if context != "" {
            response.set("context", context)
          }
          if origin != "" {
            response.set("origin", origin)
          }
          if device != "" {
            response.set("device", device)
          }
          
          @Controller.JsonResponse::new(response)
        }
        _ => {
          let error = @hashmap.new()
          error.set("success", "false")
          error.set("message", "请提供 level 与 message 字段")
          @Controller.JsonResponse::new(error)
        }
      }
    }
    None => {
      let error = @hashmap.new()
      error.set("success", "false")
      error.set("message", "请求体不能为空")
      @Controller.JsonResponse::new(error)
    }
  }
}

/// 主函数
fn main {
  println("============================================================")
  println("Autumn Framework 示例应用")
  println("============================================================")
  println("")
  
  // ========== 第一步：创建 IoC 容器 ==========
  println("📝 第一步：创建 IoC 容器")
  println("────────────────────────────────────────────────────────────")
  
  // 创建配置（类似 Spring Boot 的 application.properties）
  let config = [
    ("app.name", "User Management System"),
    ("app.version", "1.0.0"),
    ("server.port", "8080"),
    ("db.url", "jdbc:mysql://localhost:3306/users"),
    ("db.username", "root"),
    ("db.password", "password")
  ]
  
  // 创建 IoC 容器（类似 Spring 的 ApplicationContext）
  let ctx = @ApplicationContext.ApplicationContext::new(config, "com.example")
  println("✓ IoC 容器创建成功")
  println("  - 配置项数量: " + config.length().to_string())
  println("")
  
  // ========== 第二步：注册 Bean ==========
  println("📦 第二步：注册 Bean")
  println("────────────────────────────────────────────────────────────")
  
  // 注册 Bean（类似 Spring 的 @Component, @Service, @Repository）
  ctx.register_bean("userService", "com.example.service.UserService", 10, false)
  ctx.register_bean("userRepository", "com.example.repository.UserRepository", 5, false)
  ctx.register_bean("userController", "com.example.controller.UserController", 20, false)
  
  println("✓ 注册 Bean: userService (order=10)")
  println("✓ 注册 Bean: userRepository (order=5)")
  println("✓ 注册 Bean: userController (order=20)")
  println("")
  
  // ========== 第三步：创建 Bean 实例 ==========
  println("🔨 第三步：创建 Bean 实例")
  println("────────────────────────────────────────────────────────────")
  
  ctx.create_all_beans()
  println("✓ 所有 Bean 创建完成")
  println("")
  
  // ========== 第四步：创建 Web MVC 应用 ==========
  println("🌐 第四步：创建 Web MVC 应用")
  println("────────────────────────────────────────────────────────────")
  
  // 4.1 创建根路径 Controller（处理 / 请求）
  let root_controller = @Controller.Controller::new("")
    .get("/", fn(_request : @Http.HttpRequest) {
      let html_part1 = "<!DOCTYPE html><html><head><title>Autumn Framework</title>"
      let html_part2 = html_part1 + "<meta charset='utf-8'></head><body>"
      let html_part3 = html_part2 + "<style>body{font-family:Arial,sans-serif;margin:40px;}" +
                       "h1{color:#333;}ul{list-style:none;padding:0;}li{margin:10px 0;}" +
                       "a{color:#007bff;text-decoration:none;}a:hover{text-decoration:underline;}</style>"
      let html_part4 = html_part3 + "<h1>欢迎使用 Autumn Framework</h1>"
      let html_part5 = html_part4 + "<p>这是一个基于 MoonBit 的 Web 框架，类似 Spring Boot</p>"
      let html_part6 = html_part5 + "<h2>可用路由：</h2>"
      let html_part7 = html_part6 + "<ul>"
      let html_part8 = html_part7 + "<li><a href='/login'>GET /login</a> - 登录页面</li>"
      let html_part9 = html_part8 + "<li><a href='/users'>GET /users</a> - 用户列表（HTML）</li>"
      let html_part10 = html_part9 + "<li><a href='/users/123'>GET /users/123</a> - 用户详情（HTML）</li>"
      let html_part11 = html_part10 + "<li><a href='/api/users'>GET /api/users</a> - 用户列表（JSON）</li>"
      let html_part12 = html_part11 + "<li><a href='/api/users/123'>GET /api/users/123</a> - 用户详情（JSON）</li>"
      let html = html_part12 + "</ul></body></html>"
      @Http.HttpResponse::ok(html)
    })
    
    // GET /login - 登录页面（前端页面已写好，这里返回简单提示）
    .get("/login", fn(_request : @Http.HttpRequest) {
      // 注意：实际的前端登录页面应该由前端框架（Next.js）提供
      // 这里返回一个简单的提示页面，或者重定向到前端
      let html_part1 = "<!DOCTYPE html><html><head><title>登录</title>"
      let html_part2 = html_part1 + "<meta charset='utf-8'></head><body>"
      let html_part3 = html_part2 + "<style>body{font-family:Arial,sans-serif;margin:40px;text-align:center;}" +
                       "h1{color:#333;}.info{padding:20px;background:#f5f5f5;border-radius:5px;margin:20px auto;max-width:600px;}</style>"
      let html_part4 = html_part3 + "<h1>登录页面</h1>"
      let html_part5 = html_part4 + "<div class='info'>"
      let html_part6 = html_part5 + "<p>前端登录页面应该由 Next.js 框架提供</p>"
      let html_part7 = html_part6 + "<p>请访问前端应用：<a href='http://localhost:3000/login'>http://localhost:3000/login</a></p>"
      let html_part8 = html_part7 + "<p><strong>后端登录接口：</strong> POST /api/auth/login</p>"
      let html_part9 = html_part8 + "<p><strong>测试账号：</strong></p>"
      let html_part10 = html_part9 + "<ul style='text-align:left;display:inline-block;'>"
      let html_part11 = html_part10 + "<li>用户名: admin, 密码: 123456</li>"
      let html_part12 = html_part11 + "<li>用户名: user, 密码: password</li>"
      let html_part13 = html_part12 + "</ul>"
      let html_part14 = html_part13 + "</div>"
      let html = html_part14 + "</body></html>"
      @Http.HttpResponse::ok(html)
    })
    
    // GET /favicon.ico - 处理浏览器自动请求的图标
    .get("/favicon.ico", fn(_request : @Http.HttpRequest) {
      // 返回 204 No Content，避免 404 错误
      @Http.HttpResponse::no_content()
    })
  
  println("✓ 创建根路径 Controller: /")
  
  // 4.2 创建用户 Controller（类似 Spring 的 @Controller）
  let user_controller = @Controller.Controller::new("/users")
    // GET /users（类似 @GetMapping("/")）
    .get("/", fn(_request : @Http.HttpRequest) {
      let html_part1 = "<!DOCTYPE html><html><head><title>用户列表</title>"
      let html_part2 = html_part1 + "<meta charset='utf-8'></head><body>"
      let html_part3 = html_part2 + "<style>body{font-family:Arial,sans-serif;margin:40px;}h1{color:#333;}" +
                       "ul{list-style:none;padding:0;}li{padding:10px;background:#f5f5f5;margin:5px 0;border-radius:5px;}</style>"
      let html_part4 = html_part3 + "<h1>用户列表</h1>"
      let html_part5 = html_part4 + "<ul>"
      let html_part6 = html_part5 + "<li><strong>用户 1:</strong> Alice - alice@example.com</li>"
      let html_part7 = html_part6 + "<li><strong>用户 2:</strong> Bob - bob@example.com</li>"
      let html_part8 = html_part7 + "<li><strong>用户 3:</strong> Charlie - charlie@example.com</li>"
      let html_part9 = html_part8 + "</ul>"
      let html_part10 = html_part9 + "<p><a href='/'>返回首页</a></p>"
      let html = html_part10 + "</body></html>"
      @Http.HttpResponse::ok(html)
    })
    
    // GET /users/{id}（类似 @GetMapping("/{id}")）
    .get("/{id}", fn(request : @Http.HttpRequest) {
      let path = request.get_path()
      let html_part1 = "<!DOCTYPE html><html><head><title>用户详情</title>"
      let html_part2 = html_part1 + "<meta charset='utf-8'></head><body>"
      let html_part3 = html_part2 + "<style>body{font-family:Arial,sans-serif;margin:40px;}h1{color:#333;}" +
                       ".info{padding:20px;background:#f5f5f5;border-radius:5px;margin:20px 0;}</style>"
      let html_part4 = html_part3 + "<h1>用户详情</h1>"
      let html_part5 = html_part4 + "<div class='info'>"
      let html_part6 = html_part5 + "<p><strong>路径:</strong> " + path + "</p>"
      let html_part7 = html_part6 + "<p><strong>用户ID:</strong> 从路径中提取</p>"
      let html_part8 = html_part7 + "<p><strong>状态:</strong> 已找到</p>"
      let html_part9 = html_part8 + "</div>"
      let html_part10 = html_part9 + "<p><a href='/users'>返回用户列表</a> | <a href='/'>返回首页</a></p>"
      let html = html_part10 + "</body></html>"
      @Http.HttpResponse::ok(html)
    })
    
    // POST /users（类似 @PostMapping("/")）
    .post("/", fn(_request : @Http.HttpRequest) {
      let html_part1 = "<!DOCTYPE html><html><head><title>创建用户</title>"
      let html_part2 = html_part1 + "<meta charset='utf-8'></head><body>"
      let html_part3 = html_part2 + "<style>body{font-family:Arial,sans-serif;margin:40px;}h1{color:#28a745;}</style>"
      let html_part4 = html_part3 + "<h1>✓ 创建用户成功</h1>"
      let html_part5 = html_part4 + "<p>用户已成功创建</p>"
      let html_part6 = html_part5 + "<p><a href='/users'>查看用户列表</a> | <a href='/'>返回首页</a></p>"
      let html = html_part6 + "</body></html>"
      @Http.HttpResponse::created(html)
    })
    
    // PUT /users/{id}（类似 @PutMapping("/{id}")）
    .put("/{id}", fn(_request : @Http.HttpRequest) {
      let html = "<!DOCTYPE html><html><head><title>更新用户</title><meta charset='utf-8'></head><body>" +
                 "<h1>✓ 更新用户成功</h1>" +
                 "<p><a href='/users'>返回用户列表</a></p>" +
                 "</body></html>"
      @Http.HttpResponse::ok(html)
    })
    
    // DELETE /users/{id}（类似 @DeleteMapping("/{id}")）
    .delete("/{id}", fn(_request : @Http.HttpRequest) {
      let html = "<!DOCTYPE html><html><head><title>删除用户</title><meta charset='utf-8'></head><body>" +
                 "<h1>✓ 删除用户成功</h1>" +
                 "<p><a href='/users'>返回用户列表</a></p>" +
                 "</body></html>"
      @Http.HttpResponse::ok(html)
    })
  
  println("✓ 创建 Controller: /users")
  
  // 4.3 创建登录认证 Controller（类似 Spring 的 @RestController）
  let auth_controller = @Controller.RestController::new("/api/auth")
    // GET /api/auth/login（返回接口说明信息）
    .get("/login", fn(_request : @Http.HttpRequest) {
      let data = @hashmap.new()
      data.set("message", "此接口需要使用 POST 方法提交登录信息")
      data.set("method", "POST")
      data.set("url", "/api/auth/login")
      data.set("content_type", "application/json")
      data.set("request_body", "{\"username\":\"admin\",\"password\":\"123456\"}")
      data.set("test_accounts", "用户名: admin/123456 或 user/password")
      @Controller.JsonResponse::new(data)
    })
    // POST /api/auth/login（类似 @PostMapping("/login")）
    .post("/login", fn(request : @Http.HttpRequest) {
      handle_login(request)
    })
    
    // POST /api/auth/logout（类似 @PostMapping("/logout")）
    .post("/logout", fn(request : @Http.HttpRequest) {
      handle_logout(request)
    })
  
  println("✓ 创建认证 Controller: /api/auth")
  
  // 4.4 创建 REST API Controller（类似 Spring 的 @RestController）
  let api_controller = @Controller.RestController::new("/api/users")
    // GET /api/users（类似 @GetMapping("/")）
    .get("/", fn(_request : @Http.HttpRequest) {
      let data = @hashmap.new()
      data.set("id", "1")
      data.set("name", "Alice")
      data.set("email", "alice@example.com")
      @Controller.JsonResponse::new(data)
    })
    
    // GET /api/users/{id}（类似 @GetMapping("/{id}")）
    .get("/{id}", fn(request : @Http.HttpRequest) {
      let path = request.get_path()
      let data = @hashmap.new()
      // 从路径中提取 ID（简化处理）
      data.set("id", path)
      data.set("name", "Bob")
      data.set("email", "bob@example.com")
      @Controller.JsonResponse::new(data)
    })
    
    // POST /api/users（类似 @PostMapping("/")）
    .post("/", fn(_request : @Http.HttpRequest) {
      let data = @hashmap.new()
      data.set("id", "2")
      data.set("name", "Charlie")
      data.set("email", "charlie@example.com")
      @Controller.JsonResponse::new(data)
    })
    
    // PUT /api/users/{id}（类似 @PutMapping("/{id}")）
    .put("/{id}", fn(_request : @Http.HttpRequest) {
      let data = @hashmap.new()
      data.set("id", "1")
      data.set("name", "Alice Updated")
      data.set("email", "alice.updated@example.com")
      @Controller.JsonResponse::new(data)
    })
    
    // DELETE /api/users/{id}（类似 @DeleteMapping("/{id}")）
    .delete("/{id}", fn(_request : @Http.HttpRequest) {
      let data = @hashmap.new()
      data.set("status", "deleted")
      data.set("message", "用户已删除")
      @Controller.JsonResponse::new(data)
    })
  
  println("✓ 创建 RestController: /api/users")
  
  // 4.5 创建用户系统 RestController
  let user_api_controller = @Controller.RestController::new("/api/user")
    .post("/register", fn(request : @Http.HttpRequest) {
      match parse_request_params(request) {
        Some(params) => {
          match (params.get("username"), params.get("password")) {
            (Some(username), Some(password)) => {
              let display_name = opt_string_or(params.get("displayName"), username + "_user")
              let email = opt_string_or(params.get("email"), username + "@example.com")
              let response = @hashmap.new()
              response.set("success", "true")
              response.set("userId", "user-" + username)
              response.set("username", username)
              response.set("displayName", display_name)
              response.set("email", email)
              response.set("token", "token-" + username + "-" + password.length().to_string())
              response.set("channel", opt_string_or(params.get("channel"), "default"))
              @Controller.JsonResponse::new(response)
            }
            _ => {
              let error = @hashmap.new()
              error.set("success", "false")
              error.set("message", "username 与 password 为必填项")
              @Controller.JsonResponse::new(error)
            }
          }
        }
        None => {
          let error = @hashmap.new()
          error.set("success", "false")
          error.set("message", "请求体不能为空")
          @Controller.JsonResponse::new(error)
        }
      }
    })
    .post("/login", fn(request : @Http.HttpRequest) {
      match parse_request_params(request) {
        Some(params) => {
          match (params.get("username"), params.get("password")) {
            (Some(username), Some(password)) => {
              let remember = opt_string_or(params.get("remember"), "false")
              let issued_at = opt_string_or(params.get("timestamp"), "")
              let response = @hashmap.new()
              response.set("success", "true")
              response.set("username", username)
              response.set("token", "token-" + username + "-" + password.length().to_string())
              response.set("remember", remember)
              if issued_at != "" {
                response.set("issuedAt", issued_at)
              }
              @Controller.JsonResponse::new(response)
            }
            _ => {
              let error = @hashmap.new()
              error.set("success", "false")
              error.set("message", "用户名或密码缺失")
              @Controller.JsonResponse::new(error)
            }
          }
        }
        None => {
          let error = @hashmap.new()
          error.set("success", "false")
          error.set("message", "请求体不能为空")
          @Controller.JsonResponse::new(error)
        }
      }
    })
    .get("/info", fn(request : @Http.HttpRequest) {
      let auth_header = opt_string_or(request.get_header("Authorization"), "")
      let bearer_token = safe_strip_prefix(auth_header, "Bearer ")
      let token_candidate = if bearer_token != "" {
        bearer_token
      } else {
        opt_string_or(request.get_query_param("token"), "")
      }
      let token_parts = Array::from_iter(token_candidate.split("-"))
      let resolved_username = if token_parts.length() >= 2 {
        token_parts[1].to_string()
      } else if token_candidate != "" {
        token_candidate
      } else {
        "guest"
      }
      let detail = opt_string_or(request.get_query_param("detail"), "basic")
      let response = @hashmap.new()
      response.set("success", "true")
      response.set("username", resolved_username)
      response.set("token", token_candidate)
      response.set("detail", detail)
      response.set("avatar", "https://cdn.example.com/avatar/" + resolved_username + ".png")
      response.set("roles", opt_string_or(request.get_query_param("roles"), "USER"))
      @Controller.JsonResponse::new(response)
    })
    .put("/update", fn(request : @Http.HttpRequest) {
      match parse_request_params(request) {
        Some(params) => {
          let nickname = opt_string_or(params.get("nickname"), "")
          let email = opt_string_or(params.get("email"), "")
          let avatar = opt_string_or(params.get("avatar"), "")
          if nickname == "" && email == "" && avatar == "" {
            let error = @hashmap.new()
            error.set("success", "false")
            error.set("message", "请至少提供一个需要更新的字段")
            @Controller.JsonResponse::new(error)
          } else {
            let response = @hashmap.new()
            response.set("success", "true")
            if nickname != "" {
              response.set("nickname", nickname)
            }
            if email != "" {
              response.set("email", email)
            }
            if avatar != "" {
              response.set("avatar", avatar)
            }
            response.set("updatedAt", opt_string_or(params.get("timestamp"), ""))
            @Controller.JsonResponse::new(response)
          }
        }
        None => {
          let error = @hashmap.new()
          error.set("success", "false")
          error.set("message", "请求体不能为空")
          @Controller.JsonResponse::new(error)
        }
      }
    })
    .post("/avatar", fn(request : @Http.HttpRequest) {
      match parse_request_params(request) {
        Some(params) => {
          match params.get("fileName") {
            Some(file_name) => {
              let file_size = opt_string_or(params.get("fileSize"), "0")
              let checksum = opt_string_or(params.get("checksum"), "")
              let content_type = opt_string_or(params.get("contentType"), "image/png")
              let response = @hashmap.new()
              response.set("success", "true")
              response.set("fileName", file_name)
              response.set("fileSize", file_size)
              response.set("contentType", content_type)
              response.set("checksum", checksum)
              response.set("avatarUrl", "https://cdn.example.com/avatar/" + file_name)
              @Controller.JsonResponse::new(response)
            }
            None => {
              let error = @hashmap.new()
              error.set("success", "false")
              error.set("message", "fileName 为必填项")
              @Controller.JsonResponse::new(error)
            }
          }
        }
        None => {
          let error = @hashmap.new()
          error.set("success", "false")
          error.set("message", "请求体不能为空")
          @Controller.JsonResponse::new(error)
        }
      }
    })
  
  println("✓ 创建用户系统 API: /api/user")
  
  // 4.6 创建视频模块 RestController
  let video_api_controller = @Controller.RestController::new("/api/video")
    .post("/upload", fn(request : @Http.HttpRequest) {
      match parse_request_params(request) {
        Some(params) => {
          match (params.get("title"), params.get("fileName")) {
            (Some(title), Some(file_name)) => {
              let size = opt_string_or(params.get("fileSize"), "0")
              let duration = opt_string_or(params.get("duration"), "0")
              let category = opt_string_or(params.get("category"), "general")
              let response = @hashmap.new()
              response.set("success", "true")
              response.set("videoId", "video-" + title)
              response.set("title", title)
              response.set("fileName", file_name)
              response.set("fileSize", size)
              response.set("duration", duration)
              response.set("category", category)
              response.set("transcodeTaskId", "job-" + file_name)
              @Controller.JsonResponse::new(response)
            }
            _ => {
              let error = @hashmap.new()
              error.set("success", "false")
              error.set("message", "title 与 fileName 为必填项")
              @Controller.JsonResponse::new(error)
            }
          }
        }
        None => {
          let error = @hashmap.new()
          error.set("success", "false")
          error.set("message", "请求体不能为空")
          @Controller.JsonResponse::new(error)
        }
      }
    })
    .get("/list", fn(request : @Http.HttpRequest) {
      let page = opt_string_or(request.get_query_param("page"), "1")
      let page_size = opt_string_or(request.get_query_param("pageSize"), "10")
      let category = opt_string_or(request.get_query_param("category"), "all")
      let keyword = opt_string_or(request.get_query_param("keyword"), "")
      let base_id = "video-" + page
      let title_prefix = if keyword != "" { keyword } else { "视频" + page }
      let item1 = "{\"id\":\"" + base_id + "-a\",\"title\":\"" + title_prefix + " A\",\"cover\":\"https://cdn.example.com/" + base_id + "-a.jpg\"}"
      let item2 = "{\"id\":\"" + base_id + "-b\",\"title\":\"" + title_prefix + " B\",\"cover\":\"https://cdn.example.com/" + base_id + "-b.jpg\"}"
      let items = "[" + item1 + "," + item2 + "]"
      let meta = "{\"page\":\"" + page + "\",\"pageSize\":\"" + page_size + "\",\"category\":\"" + category + "\",\"hasNext\":\"true\"}"
      let response = @hashmap.new()
      response.set("success", "true")
      response.set("items", items)
      response.set("meta", meta)
      @Controller.JsonResponse::new(response)
    })
    .get("/{id}", fn(request : @Http.HttpRequest) {
      let video_id = extract_path_tail(request.get_path())
      let response = @hashmap.new()
      response.set("success", "true")
      response.set("videoId", video_id)
      response.set("title", "视频 - " + video_id)
      response.set("cover", "https://cdn.example.com/" + video_id + ".jpg")
      response.set("duration", opt_string_or(request.get_query_param("duration"), "180"))
      response.set("playUrl", "https://cdn.example.com/stream/" + video_id + ".m3u8")
      response.set("description", "视频 " + video_id + " 的动态描述")
      @Controller.JsonResponse::new(response)
    })
    .post("/{id}/like", fn(request : @Http.HttpRequest) {
      let video_id = extract_path_tail(request.get_path())
      match parse_request_params(request) {
        Some(params) => {
          let action = opt_string_or(params.get("action"), "toggle")
          let response = @hashmap.new()
          response.set("success", "true")
          response.set("videoId", video_id)
          response.set("action", action)
          response.set(
            "status",
            if action == "cancel" { "unliked" } else { "liked" },
          )
          @Controller.JsonResponse::new(response)
        }
        None => {
          let response = @hashmap.new()
          response.set("success", "true")
          response.set("videoId", video_id)
          response.set("action", "toggle")
          response.set("status", "liked")
          @Controller.JsonResponse::new(response)
        }
      }
    })
    .post("/{id}/favorite", fn(request : @Http.HttpRequest) {
      let video_id = extract_path_tail(request.get_path())
      match parse_request_params(request) {
        Some(params) => {
          let action = opt_string_or(params.get("action"), "toggle")
          let response = @hashmap.new()
          response.set("success", "true")
          response.set("videoId", video_id)
          response.set("action", action)
          response.set(
            "status",
            if action == "cancel" { "removed" } else { "favorited" },
          )
          @Controller.JsonResponse::new(response)
        }
        None => {
          let response = @hashmap.new()
          response.set("success", "true")
          response.set("videoId", video_id)
          response.set("action", "toggle")
          response.set("status", "favorited")
          @Controller.JsonResponse::new(response)
        }
      }
    })
    .get("/{id}/comments", fn(request : @Http.HttpRequest) {
      let video_id = extract_path_tail(request.get_path())
      let page = opt_string_or(request.get_query_param("page"), "1")
      let item1 = "{\"id\":\"" + video_id + "-c" + page + "1\",\"author\":\"demo_user\",\"content\":\"好视频！第 " + page + " 页\",\"createdAt\":\"2025-11-08T12:00:00Z\"}"
      let item2 = "{\"id\":\"" + video_id + "-c" + page + "2\",\"author\":\"guest\",\"content\":\"点赞学习\",\"createdAt\":\"2025-11-08T12:05:00Z\"}"
      let comments = "[" + item1 + "," + item2 + "]"
      let response = @hashmap.new()
      response.set("success", "true")
      response.set("videoId", video_id)
      response.set("comments", comments)
      response.set("page", page)
      @Controller.JsonResponse::new(response)
    })
    .post("/{id}/comment", fn(request : @Http.HttpRequest) {
      let video_id = extract_path_tail(request.get_path())
      match parse_request_params(request) {
        Some(params) => {
          match params.get("content") {
            Some(content) => {
              let author = opt_string_or(params.get("author"), "anonymous")
              let response = @hashmap.new()
              response.set("success", "true")
              response.set("videoId", video_id)
              response.set("commentId", video_id + "-c" + author)
              response.set("author", author)
              response.set("content", content)
              response.set("createdAt", opt_string_or(params.get("timestamp"), ""))
              @Controller.JsonResponse::new(response)
            }
            None => {
              let error = @hashmap.new()
              error.set("success", "false")
              error.set("message", "content 为必填项")
              @Controller.JsonResponse::new(error)
            }
          }
        }
        None => {
          let error = @hashmap.new()
          error.set("success", "false")
          error.set("message", "请求体不能为空")
          @Controller.JsonResponse::new(error)
        }
      }
    })
    .get("/recommend", fn(request : @Http.HttpRequest) {
      let user_id = opt_string_or(request.get_query_param("userId"), "anonymous")
      let seed = opt_string_or(request.get_query_param("seed"), "popular")
      let stream = "[" +
        "{\"id\":\"rec-" + seed + "-1\",\"title\":\"为 " + user_id + " 推荐的视频 1\"}," +
        "{\"id\":\"rec-" + seed + "-2\",\"title\":\"为 " + user_id + " 推荐的视频 2\"}" +
      "]"
      let response = @hashmap.new()
      response.set("success", "true")
      response.set("userId", user_id)
      response.set("seed", seed)
      response.set("items", stream)
      @Controller.JsonResponse::new(response)
    })
  
  println("✓ 创建视频模块 API: /api/video")
  
  // 4.7 创建搜索 API
  let search_controller = @Controller.RestController::new("/api")
    .get("/search", fn(request : @Http.HttpRequest) {
      let keyword = opt_string_or(request.get_query_param("q"), "")
      if keyword == "" {
        let error = @hashmap.new()
        error.set("success", "false")
        error.set("message", "q 为必填查询参数")
        return @Controller.JsonResponse::new(error)
      }
      let page = opt_string_or(request.get_query_param("page"), "1")
      let results = "[" +
        "{\"id\":\"search-" + keyword + "-1\",\"title\":\"" + keyword + " 相关视频 A\"}," +
        "{\"id\":\"search-" + keyword + "-2\",\"title\":\"" + keyword + " 相关视频 B\"}" +
      "]"
      let response = @hashmap.new()
      response.set("success", "true")
      response.set("keyword", keyword)
      response.set("page", page)
      response.set("results", results)
      @Controller.JsonResponse::new(response)
    })
  
  println("✓ 创建搜索 API: /api/search")
  
  // 4.8 创建 AI 互动接口
  let ai_controller = @Controller.RestController::new("/api/ai")
    .post("/chat", fn(request : @Http.HttpRequest) {
      match parse_request_params(request) {
        Some(params) => {
          match params.get("prompt") {
            Some(prompt) => {
              let session_id = opt_string_or(params.get("sessionId"), "session-temp")
              let response = @hashmap.new()
              response.set("success", "true")
              response.set("sessionId", session_id)
              response.set("reply", "AI 针对 \"" + prompt + "\" 的示例回答")
              response.set("promptTokens", prompt.length().to_string())
              @Controller.JsonResponse::new(response)
            }
            None => {
              let error = @hashmap.new()
              error.set("success", "false")
              error.set("message", "prompt 为必填项")
              @Controller.JsonResponse::new(error)
            }
          }
        }
        None => {
          let error = @hashmap.new()
          error.set("success", "false")
          error.set("message", "请求体不能为空")
          @Controller.JsonResponse::new(error)
        }
      }
    })
    .post("/voice", fn(request : @Http.HttpRequest) {
      match parse_request_params(request) {
        Some(params) => {
          match params.get("voiceId") {
            Some(voice_id) => {
              let response = @hashmap.new()
              response.set("success", "true")
              response.set("voiceId", voice_id)
              response.set("transcript", opt_string_or(params.get("transcript"), ""))
              response.set("reply", "AI 语音回复已生成")
              @Controller.JsonResponse::new(response)
            }
            None => {
              let error = @hashmap.new()
              error.set("success", "false")
              error.set("message", "voiceId 为必填项")
              @Controller.JsonResponse::new(error)
            }
          }
        }
        None => {
          let error = @hashmap.new()
          error.set("success", "false")
          error.set("message", "请求体不能为空")
          @Controller.JsonResponse::new(error)
        }
      }
    })
    .post("/emotion", fn(request : @Http.HttpRequest) {
      match parse_request_params(request) {
        Some(params) => {
          match params.get("content") {
            Some(content) => {
              let response = @hashmap.new()
              response.set("success", "true")
              response.set("emotion", opt_string_or(params.get("target"), "neutral"))
              response.set("score", "0.82")
              response.set("contentPreview", content)
              @Controller.JsonResponse::new(response)
            }
            None => {
              let error = @hashmap.new()
              error.set("success", "false")
              error.set("message", "content 为必填项")
              @Controller.JsonResponse::new(error)
            }
          }
        }
        None => {
          let error = @hashmap.new()
          error.set("success", "false")
          error.set("message", "请求体不能为空")
          @Controller.JsonResponse::new(error)
        }
      }
    })
  
  println("✓ 创建 AI 互动 API: /api/ai")
  
  // 4.9 创建 WebSocket 协调接口（HTTP 返回握手信息）
  let ws_controller = @Controller.RestController::new("/ws")
    .get("/chat", fn(request : @Http.HttpRequest) {
      let response = @hashmap.new()
      response.set("success", "true")
      response.set("protocol", "websocket")
      response.set("endpoint", "ws://" + opt_string_or(request.get_header("Host"), "localhost:8080") + "/ws/chat")
      response.set("note", "当前示例仅返回握手说明，实际 WebSocket 升级需底层服务器支持")
      @Controller.JsonResponse::new(response)
    })
  
  println("✓ 创建 WebSocket 信息接口: /ws/chat")
  
  // 4.10 创建系统配置 Controller（日志上传等接口）
  let system_controller = @Controller.RestController::new("/api/system")
    .get("/config", fn(request : @Http.HttpRequest) {
      let env = opt_string_or(request.get_query_param("env"), "dev")
      let response = @hashmap.new()
      response.set("success", "true")
      response.set("env", env)
      response.set("cdn", opt_string_or(request.get_query_param("cdn"), "https://cdn.example.com"))
      response.set("enableFeatureX", opt_string_or(request.get_query_param("featureX"), "false"))
      response.set("timestamp", opt_string_or(request.get_query_param("timestamp"), ""))
      @Controller.JsonResponse::new(response)
    })
    // POST /api/system/logs - 上传客户端日志
    .post("/logs", fn(request : @Http.HttpRequest) {
      handle_log_upload(request)
    })
  
  println("✓ 创建系统 Controller: /api/system")
  
  // 4.6 创建 DispatcherServlet（类似 Spring MVC 的 DispatcherServlet）
  let dispatcher = @Dispatcher.DispatcherServlet::new()
    .register_controller("rootController", root_controller)
    .register_controller("userController", user_controller)
    .register_rest_controller("authController", auth_controller)
    .register_rest_controller("apiController", api_controller)
    .register_rest_controller("userApiController", user_api_controller)
    .register_rest_controller("videoApiController", video_api_controller)
    .register_rest_controller("searchController", search_controller)
    .register_rest_controller("aiController", ai_controller)
    .register_rest_controller("wsController", ws_controller)
    .register_rest_controller("systemController", system_controller)
  
  println("✓ 创建 DispatcherServlet")
  println("")
  
  // ========== 第五步：测试请求处理 ==========
  println("🧪 第五步：测试请求处理")
  println("────────────────────────────────────────────────────────────")
  
  // 5.1 测试 GET /
  let request0 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("GET"),
    "/",
    @hashmap.new(),
    @hashmap.new(),
    None
  )
  let response0 = dispatcher.handle_request(request0)
  println("✓ GET /")
  println("  状态码: " + response0.get_status_code().to_string())
  match response0.get_body() {
    Some(body) => println("  响应体长度: " + body.length().to_string() + " 字符")
    None => println("  响应体: 无")
  }
  
  // 5.2 测试 GET /users
  let request1 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("GET"),
    "/users",
    @hashmap.new(),
    @hashmap.new(),
    None
  )
  let response1 = dispatcher.handle_request(request1)
  println("✓ GET /users")
  println("  状态码: " + response1.get_status_code().to_string())
  match response1.get_body() {
    Some(body) => println("  响应体长度: " + body.length().to_string() + " 字符")
    None => println("  响应体: 无")
  }
  
  // 5.3 测试 GET /api/users
  let request2 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("GET"),
    "/api/users",
    @hashmap.new(),
    @hashmap.new(),
    None
  )
  let response2 = dispatcher.handle_request(request2)
  println("✓ GET /api/users")
  println("  状态码: " + response2.get_status_code().to_string())
  match response2.get_body() {
    Some(body) => println("  响应体: " + body)
    None => println("  响应体: 无")
  }
  
  // 5.4 测试 GET /users/123
  let request3 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("GET"),
    "/users/123",
    @hashmap.new(),
    @hashmap.new(),
    None
  )
  let response3 = dispatcher.handle_request(request3)
  println("✓ GET /users/123")
  println("  状态码: " + response3.get_status_code().to_string())
  
  // 5.5 测试 GET /api/users/123
  let request4 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("GET"),
    "/api/users/123",
    @hashmap.new(),
    @hashmap.new(),
    None
  )
  let response4 = dispatcher.handle_request(request4)
  println("✓ GET /api/users/123")
  println("  状态码: " + response4.get_status_code().to_string())
  match response4.get_body() {
    Some(body) => println("  响应体: " + body)
    None => println("  响应体: 无")
  }
  
  // 5.6 测试 POST /api/auth/login
  let login_body = "{\"username\":\"admin\",\"password\":\"123456\"}"
  let login_headers = @hashmap.new()
  login_headers.set("Content-Type", "application/json")
  let request5 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("POST"),
    "/api/auth/login",
    @hashmap.new(),
    login_headers,
    Some(login_body)
  )
  let response5 = dispatcher.handle_request(request5)
  println("✓ POST /api/auth/login")
  println("  状态码: " + response5.get_status_code().to_string())
  match response5.get_body() {
    Some(body) => println("  响应体: " + body)
    None => println("  响应体: 无")
  }
  
  // 5.7 测试 POST /api/auth/logout
  let logout_headers = @hashmap.new()
  logout_headers.set("Content-Type", "application/json")
  let request6 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("POST"),
    "/api/auth/logout",
    @hashmap.new(),
    logout_headers,
    None
  )
  let response6 = dispatcher.handle_request(request6)
  println("✓ POST /api/auth/logout")
  println("  状态码: " + response6.get_status_code().to_string())
  match response6.get_body() {
    Some(body) => println("  响应体: " + body)
    None => println("  响应体: 无")
  }
  
  // 5.8 测试 POST /api/system/logs
  let log_payload = "{\"level\":\"INFO\",\"message\":\"初始化成功\",\"timestamp\":\"2025-11-08T12:00:00Z\",\"origin\":\"frontend\",\"device\":\"web\"}"
  let system_headers = @hashmap.new()
  system_headers.set("Content-Type", "application/json")
  system_headers.set("X-Request-Id", "req-log-demo-1")
  let request7 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("POST"),
    "/api/system/logs",
    @hashmap.new(),
    system_headers,
    Some(log_payload)
  )
  let response7 = dispatcher.handle_request(request7)
  println("✓ POST /api/system/logs")
  println("  状态码: " + response7.get_status_code().to_string())
  match response7.get_body() {
    Some(body) => println("  响应体: " + body)
    None => println("  响应体: 无")
  }
  
  // 5.9 测试 POST /api/user/register
  let register_body = "{\"username\":\"demo_user\",\"password\":\"pass123\",\"displayName\":\"示例用户\",\"channel\":\"ios\"}"
  let register_headers = @hashmap.new()
  register_headers.set("Content-Type", "application/json")
  let request8 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("POST"),
    "/api/user/register",
    @hashmap.new(),
    register_headers,
    Some(register_body)
  )
  let response8 = dispatcher.handle_request(request8)
  println("✓ POST /api/user/register")
  println("  状态码: " + response8.get_status_code().to_string())
  match response8.get_body() {
    Some(body) => println("  响应体: " + body)
    None => println("  响应体: 无")
  }
  
  // 5.10 测试 GET /api/video/list
  let request9 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("GET"),
    "/api/video/list?page=1&pageSize=2&keyword=moonbit",
    @hashmap.new(),
    @hashmap.new(),
    None
  )
  let response9 = dispatcher.handle_request(request9)
  println("✓ GET /api/video/list")
  println("  状态码: " + response9.get_status_code().to_string())
  match response9.get_body() {
    Some(body) => println("  响应体: " + body)
    None => println("  响应体: 无")
  }
  
  // 5.11 测试 GET /api/search?q=moonbit
  let request10 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("GET"),
    "/api/search?q=moonbit&page=1",
    @hashmap.new(),
    @hashmap.new(),
    None
  )
  let response10 = dispatcher.handle_request(request10)
  println("✓ GET /api/search")
  println("  状态码: " + response10.get_status_code().to_string())
  match response10.get_body() {
    Some(body) => println("  响应体: " + body)
    None => println("  响应体: 无")
  }
  
  // 5.12 测试 POST /api/ai/chat
  let ai_body = "{\"prompt\":\"请推荐一部科幻电影\",\"sessionId\":\"session-demo\"}"
  let ai_headers = @hashmap.new()
  ai_headers.set("Content-Type", "application/json")
  let request11 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("POST"),
    "/api/ai/chat",
    @hashmap.new(),
    ai_headers,
    Some(ai_body)
  )
  let response11 = dispatcher.handle_request(request11)
  println("✓ POST /api/ai/chat")
  println("  状态码: " + response11.get_status_code().to_string())
  match response11.get_body() {
    Some(body) => println("  响应体: " + body)
    None => println("  响应体: 无")
  }
  
  // 5.13 测试 GET /ws/chat
  let ws_headers = @hashmap.new()
  ws_headers.set("Host", "localhost:8080")
  let request12 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("GET"),
    "/ws/chat",
    @hashmap.new(),
    ws_headers,
    None
  )
  let response12 = dispatcher.handle_request(request12)
  println("✓ GET /ws/chat")
  println("  状态码: " + response12.get_status_code().to_string())
  match response12.get_body() {
    Some(body) => println("  响应体: " + body)
    None => println("  响应体: 无")
  }
  
  // 5.14 测试 404
  let request13 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("GET"),
    "/not-found",
    @hashmap.new(),
    @hashmap.new(),
    None
  )
  let response13 = dispatcher.handle_request(request13)
  println("✓ GET /not-found (404)")
  println("  状态码: " + response13.get_status_code().to_string())
  println("")
  
  // ========== 第六步：查看容器状态 ==========
  println("📊 第六步：查看容器状态")
  println("────────────────────────────────────────────────────────────")
  
  ctx.print_summary()
  println("")
  
  // ========== 第七步：使用 Boot 启动应用 ==========
  println("🚀 第七步：使用 Boot 启动应用")
  println("────────────────────────────────────────────────────────────")
  
  println("✓ 准备启动嵌入式服务器...")
  println("  端口: 8080")
  println("  访问地址: http://localhost:8080")
  println("")
  println("📌 可用端点：")
  println("  - GET  http://localhost:8080/              - 首页")
  println("  - GET  http://localhost:8080/users         - 用户列表（HTML）")
  println("  - GET  http://localhost:8080/users/{id}     - 用户详情（HTML）")
  println("  - POST http://localhost:8080/users          - 创建用户（HTML）")
  println("  - GET  http://localhost:8080/api/users      - 用户列表（JSON）")
  println("  - GET  http://localhost:8080/api/users/{id} - 用户详情（JSON）")
  println("  - POST http://localhost:8080/api/users      - 创建用户（JSON）")
  println("  - POST http://localhost:8080/api/auth/login  - 用户登录（JSON）")
  println("  - POST http://localhost:8080/api/auth/logout - 用户登出（JSON）")
  println("  - POST http://localhost:8080/api/user/register - 视频站注册用户")
  println("  - POST http://localhost:8080/api/user/login    - 视频站用户登录")
  println("  - GET  http://localhost:8080/api/user/info     - 获取用户信息")
  println("  - PUT  http://localhost:8080/api/user/update   - 修改用户资料")
  println("  - POST http://localhost:8080/api/user/avatar   - 上传用户头像")
  println("  - POST http://localhost:8080/api/video/upload  - 上传视频")
  println("  - GET  http://localhost:8080/api/video/list    - 视频列表")
  println("  - GET  http://localhost:8080/api/video/{id}    - 视频详情")
  println("  - POST http://localhost:8080/api/video/{id}/like     - 点赞/取消点赞")
  println("  - POST http://localhost:8080/api/video/{id}/favorite - 收藏/取消收藏")
  println("  - GET  http://localhost:8080/api/video/{id}/comments - 评论列表")
  println("  - POST http://localhost:8080/api/video/{id}/comment  - 发表评论")
  println("  - GET  http://localhost:8080/api/video/recommend - 视频推荐流")
  println("  - GET  http://localhost:8080/api/search        - 视频搜索")
  println("  - POST http://localhost:8080/api/ai/chat       - AI 文本对话")
  println("  - POST http://localhost:8080/api/ai/voice      - AI 语音对话")
  println("  - POST http://localhost:8080/api/ai/emotion    - 情绪检测")
  println("  - GET  http://localhost:8080/ws/chat           - WebSocket 握手信息")
  println("  - GET  http://localhost:8080/api/system/config - 获取系统配置")
  println("  - POST http://localhost:8080/api/system/logs - 上传客户端日志（JSON 或表单）")
  println("")
  println("📌 测试账号：")
  println("  - 用户名: admin, 密码: 123456")
  println("  - 用户名: user, 密码: password")
  println("")
  
  // 使用 BootApplication 启动应用（类似 Spring Boot 的 @SpringBootApplication）
  // BootApplication::run() 会阻塞，直到服务器停止
  @Boot.BootApplication::run(8080, fn() {
    dispatcher
  })
  
  // 服务器停止后才会执行到这里
  println("")
  println("============================================================")
  println("✨ 服务器已停止，示例应用完成！")
  println("============================================================")
}
