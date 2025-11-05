# Summer Demo - Autumn Framework 示例

这是一个参考 [summer-framework](https://github.com/michaelliao/summer-framework) 实现的简单示例，展示如何使用 Autumn Framework 创建一个完整的 Web 应用。

---

## 📋 功能特性

这个示例展示了 Autumn Framework 的核心功能：

1. **IoC 容器** - 使用 ApplicationContext 管理 Bean
2. **配置管理** - 使用 PropertyResolver 管理配置
3. **Web MVC** - 使用 Controller 和 RestController 处理请求
4. **请求分发** - 使用 DispatcherServlet 分发请求
5. **Boot 启动** - 使用 BootApplication 启动应用

---

## 🚀 快速开始

### 1. 运行示例

```bash
cd summer-demo
moon run
```

### 2. 查看输出

示例会输出以下内容：

```
============================================================
Autumn Framework 示例应用
============================================================

📝 第一步：创建 IoC 容器
────────────────────────────────────────────────────────────
✓ IoC 容器创建成功
  - 配置项数量: 6

📦 第二步：注册 Bean
────────────────────────────────────────────────────────────
✓ 注册 Bean: userService
✓ 注册 Bean: userController

🔨 第三步：创建 Bean 实例
────────────────────────────────────────────────────────────
✓ 所有 Bean 创建完成

🌐 第四步：创建 Web MVC 应用
────────────────────────────────────────────────────────────
✓ 创建 Controller: /users
✓ 创建 RestController: /api/users
✓ 创建 DispatcherServlet

🧪 第五步：测试请求处理
────────────────────────────────────────────────────────────
✓ GET /users
  状态码: 200
  响应体长度: 156 字符
✓ GET /api/users
  状态码: 200
  响应体: {"id":"1","name":"Alice","email":"alice@example.com"}
✓ GET /users/123
  状态码: 200
✓ GET /not-found (404)
  状态码: 404

📊 第六步：查看容器状态
────────────────────────────────────────────────────────────
=== ApplicationContext 状态 ===
Bean 定义数量: 2
已创建实例: 2

--- Bean 列表 ---
  userService: com.example.service.UserService [已创建]
  userController: com.example.controller.UserController [已创建]

🚀 第七步：使用 Boot 启动应用
────────────────────────────────────────────────────────────
✓ 准备启动嵌入式服务器...
  端口: 8080
  访问地址: http://localhost:8080

[Boot] Starting Autumn Boot application...
[Server] Starting embedded server on port 8080
[Server] Server is running at http://localhost:8080
[Server] Press Ctrl+C to stop the server
[Boot] Application started successfully!
[Boot] Server is running at http://localhost:8080
[Boot] Press Ctrl+C to stop the server
[Demo] Application started!

============================================================
✨ 示例应用完成！
============================================================
```

---

## 📝 代码说明

### 1. IoC 容器

```moonbit
// 创建配置
let config = [
  ("app.name", "Summer Demo"),
  ("app.version", "1.0.0"),
  ("server.port", "8080"),
  ("db.url", "jdbc:mysql://localhost:3306/test"),
  ("db.username", "root"),
  ("db.password", "password")
]

// 创建 IoC 容器
let ctx = @ApplicationContext.ApplicationContext::new(config, "com.example")
```

### 2. 注册 Bean

```moonbit
// 注册 Bean
ctx.register_bean("userService", "com.example.service.UserService", 10, false)
ctx.register_bean("userController", "com.example.controller.UserController", 20, false)

// 创建 Bean 实例
ctx.create_all_beans()
```

### 3. 创建 Controller

```moonbit
// 创建 Controller
let user_controller = @Controller.Controller::new("/users")
  .get("/", fn(request) {
    // 处理 GET /users 请求
    @Http.HttpResponse::ok("<html>...</html>")
  })
  .get("/{id}", fn(request) {
    // 处理 GET /users/{id} 请求
    @Http.HttpResponse::ok("<html>...</html>")
  })
  .post("/", fn(request) {
    // 处理 POST /users 请求
    @Http.HttpResponse::created("<html>...</html>")
  })
```

### 4. 创建 RestController

```moonbit
// 创建 RestController
let api_controller = @RestController.RestController::new("/api/users")
  .get("/", fn(request) {
    // 返回 JSON 响应
    let mut data = @hashmap.new()
    data.set("id", "1")
    data.set("name", "Alice")
    @RestController.JsonResponse::new(data)
  })
```

### 5. 创建 DispatcherServlet

```moonbit
// 创建 DispatcherServlet
let dispatcher = @Dispatcher.DispatcherServlet::new()
  .register_controller("userController", user_controller)
  .register_rest_controller("apiController", api_controller)
```

### 6. 使用 Boot 启动

```moonbit
// 使用 BootApplication 启动应用
@Boot.BootApplication::run(8080, fn() {
  dispatcher
})
```

---

## 🎯 API 端点

示例应用提供了以下 API 端点：

### Controller 端点

- `GET /users` - 获取用户列表（HTML）
- `GET /users/{id}` - 获取用户详情（HTML）
- `POST /users` - 创建用户（HTML）

### RestController 端点

- `GET /api/users` - 获取用户列表（JSON）
- `GET /api/users/{id}` - 获取用户详情（JSON）
- `POST /api/users` - 创建用户（JSON）

---

## 📊 与 summer-framework 的对比

| 功能 | summer-framework | Autumn Framework |
|------|------------------|------------------|
| IoC 容器 | ✅ | ✅ |
| 配置管理 | ✅ | ✅ |
| Web MVC | ✅ | ✅ |
| Controller | ✅ | ✅ |
| RestController | ✅ | ✅ |
| DispatcherServlet | ✅ | ✅ |
| Boot 启动 | ✅ | ✅ |

---

## 📚 参考

- [summer-framework](https://github.com/michaelliao/summer-framework) - 参考实现
- Autumn Framework 文档 - 查看 `README.md` 获取更多信息

---

## 🎉 总结

这个示例展示了如何使用 Autumn Framework 创建一个完整的 Web 应用，包括：

1. ✅ IoC 容器的使用
2. ✅ 配置管理
3. ✅ Controller 和 RestController 的创建
4. ✅ DispatcherServlet 的使用
5. ✅ Boot 启动应用

通过这个示例，你可以快速了解 Autumn Framework 的核心功能和使用方式。

