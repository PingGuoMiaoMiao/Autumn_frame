/// Autumn Framework 完整示例
/// 
/// 根据使用指南创建的完整示例，展示如何使用 Autumn Frame 构建 Web 应用
/// 类似 Spring Boot 的开发体验

// ========== 导入依赖 ==========

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
  
  // 4.5 创建 DispatcherServlet（类似 Spring MVC 的 DispatcherServlet）
  let dispatcher = @Dispatcher.DispatcherServlet::new()
    .register_controller("rootController", root_controller)
    .register_controller("userController", user_controller)
    .register_rest_controller("authController", auth_controller)
    .register_rest_controller("apiController", api_controller)
  
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
  
  // 5.8 测试 404
  let request7 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("GET"),
    "/not-found",
    @hashmap.new(),
    @hashmap.new(),
    None
  )
  let response7 = dispatcher.handle_request(request7)
  println("✓ GET /not-found (404)")
  println("  状态码: " + response7.get_status_code().to_string())
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
