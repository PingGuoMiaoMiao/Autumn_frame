///|
/// Boot 模块演示
/// 
/// 演示如何使用 Autumn Boot 模块启动 Web 应用

// ========== 导入依赖 ==========

fn main {
  // 使用 BootApplication 启动应用
  @Boot.BootApplication::run(8080, fn() {
    // 1. 创建 DispatcherServlet
    let dispatcher = @Dispatcher.DispatcherServlet::new()

    // 2. 创建 Controller（示例）
    let user_controller = @Controller.Controller::new("/users")
      .get("/", fn(request : @Http.HttpRequest) {
        @Http.HttpResponse::ok(
          "<html><body><h1>用户列表</h1></body></html>",
        )
      })
      .get("/{id}", fn(request : @Http.HttpRequest) {
        let path = request.get_path()
        @Http.HttpResponse::ok(
          "<html><body><h1>用户详情: " + path + "</h1></body></html>",
        )
      })

    // 3. 创建 RestController（示例）
    let api_controller = @Controller.RestController::new("/api/users").get(
      "/",
      fn(request : @Http.HttpRequest) {
        let data = @hashmap.new()
        data.set("id", "1")
        data.set("name", "Alice")
        @Controller.JsonResponse::new(data)
      },
    )

    // 4. 注册 Controller 和 RestController
    dispatcher
    .register_controller("userController", user_controller)
    .register_rest_controller("apiController", api_controller)
  })
  println("[Demo] Application started!")
}
