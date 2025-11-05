/// Summer Demo - Autumn Framework 示例
/// 
/// 参考 summer-framework 的实现方式，展示如何使用 Autumn Framework
/// 创建一个简单的 Web 应用

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
  
  let config = [
    ("app.name", "Summer Demo"),
    ("app.version", "1.0.0"),
    ("server.port", "8080"),
    ("db.url", "jdbc:mysql://localhost:3306/test"),
    ("db.username", "root"),
    ("db.password", "password")
  ]
  
  let ctx = @ApplicationContext.ApplicationContext::new(config, "com.example")
  println("✓ IoC 容器创建成功")
  println("  - 配置项数量: " + config.length().to_string())
  println("")
  
  // ========== 第二步：注册 Bean ==========
  println("📦 第二步：注册 Bean")
  println("────────────────────────────────────────────────────────────")
  
  ctx.register_bean("userService", "com.example.service.UserService", 10, false)
  ctx.register_bean("userController", "com.example.controller.UserController", 20, false)
  
  println("✓ 注册 Bean: userService")
  println("✓ 注册 Bean: userController")
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
  
  // 4.1 创建 Controller
  let user_controller = @Controller.Controller::new("/users")
    .get("/", fn(request : @Http.HttpRequest) {
      let html_part1 = "<html><head><title>用户列表</title></head><body>"
      let html_part2 = html_part1 + "<h1>用户列表</h1>"
      let html_part3 = html_part2 + "<ul>"
      let html_part4 = html_part3 + "<li>用户 1: Alice</li>"
      let html_part5 = html_part4 + "<li>用户 2: Bob</li>"
      let html_part6 = html_part5 + "<li>用户 3: Charlie</li>"
      let html_part7 = html_part6 + "</ul>"
      let html = html_part7 + "</body></html>"
      @Http.HttpResponse::ok(html)
    })
    .get("/{id}", fn(request : @Http.HttpRequest) {
      let path = request.get_path()
      let html_part1 = "<html><head><title>用户详情</title></head><body>"
      let html_part2 = html_part1 + "<h1>用户详情</h1>"
      let html_part3 = html_part2 + "<p>路径: " + path + "</p>"
      let html = html_part3 + "</body></html>"
      @Http.HttpResponse::ok(html)
    })
    .post("/", fn(request : @Http.HttpRequest) {
      let html_part1 = "<html><head><title>创建用户</title></head><body>"
      let html_part2 = html_part1 + "<h1>创建用户成功</h1>"
      let html = html_part2 + "</body></html>"
      @Http.HttpResponse::created(html)
    })
  
  println("✓ 创建 Controller: /users")
  
  // 4.2 创建 RestController
  let api_controller = @Controller.RestController::new("/api/users")
    .get("/", fn(request : @Http.HttpRequest) {
      let data = @hashmap.new()
      data.set("id", "1")
      data.set("name", "Alice")
      data.set("email", "alice@example.com")
      @Controller.JsonResponse::new(data)
    })
    .get("/{id}", fn(request : @Http.HttpRequest) {
      let data = @hashmap.new()
      data.set("id", request.get_path())
      data.set("name", "Bob")
      data.set("email", "bob@example.com")
      @Controller.JsonResponse::new(data)
    })
    .post("/", fn(request : @Http.HttpRequest) {
      let data = @hashmap.new()
      data.set("id", "2")
      data.set("name", "Charlie")
      data.set("email", "charlie@example.com")
      @Controller.JsonResponse::new(data)
    })
  
  println("✓ 创建 RestController: /api/users")
  
  // 4.3 创建根路径 Controller（处理 / 请求）
  let root_controller = @Controller.Controller::new("")
    .get("/", fn(_request : @Http.HttpRequest) {
      let html_part1 = "<!DOCTYPE html><html><head><title>Autumn Framework Demo</title>"
      let html_part2 = html_part1 + "<meta charset='utf-8'></head><body>"
      let html_part3 = html_part2 + "<h1>欢迎使用 Autumn Framework</h1>"
      let html_part4 = html_part3 + "<p>这是一个基于 MoonBit 的 Web 框架示例</p>"
      let html_part5 = html_part4 + "<h2>可用路由：</h2>"
      let html_part6 = html_part5 + "<ul>"
      let html_part7 = html_part6 + "<li><a href='/users'>GET /users</a> - 用户列表</li>"
      let html_part8 = html_part7 + "<li><a href='/api/users'>GET /api/users</a> - API 用户列表</li>"
      let html_part9 = html_part8 + "<li><a href='/users/123'>GET /users/123</a> - 用户详情</li>"
      let html = html_part9 + "</ul></body></html>"
      @Http.HttpResponse::ok(html)
    })
  
  // 4.4 创建 DispatcherServlet
  let dispatcher = @Dispatcher.DispatcherServlet::new()
    .register_controller("rootController", root_controller)
    .register_controller("userController", user_controller)
    .register_rest_controller("apiController", api_controller)
  
  println("✓ 创建根路径 Controller: /")
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
  
  // 5.5 测试 404
  let request4 = @Http.HttpRequest::new(
    @Http.HttpMethod::from_string("GET"),
    "/not-found",
    @hashmap.new(),
    @hashmap.new(),
    None
  )
  let response4 = dispatcher.handle_request(request4)
  println("✓ GET /not-found (404)")
  println("  状态码: " + response4.get_status_code().to_string())
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
  
  // 使用 BootApplication 启动应用
  // 注意：当前实现是占位实现，实际服务器启动需要 FFI 调用
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

