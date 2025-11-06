# Autumn Framework 完整示例

> 根据使用指南创建的完整示例，展示如何使用 Autumn Frame 构建 Web 应用

## 📋 示例说明

这个示例完整展示了 Autumn Frame 的使用方式，包括：

1. **IoC 容器** - 创建和配置 ApplicationContext
2. **Bean 注册** - 注册 Service、Repository、Controller 等 Bean
3. **Web MVC** - 创建 Controller 和 RestController
4. **请求分发** - 使用 DispatcherServlet 分发请求
5. **启动应用** - 使用 BootApplication 启动服务器

## 🚀 快速开始

### 1. 编译项目

```bash
cd autumn-demo
moon build --target native
```

### 2. 运行应用

```bash
moon run --target native
```

### 3. 访问应用

启动后，访问以下地址：

- **首页**: http://localhost:8080/
- **用户列表（HTML）**: http://localhost:8080/users
- **用户详情（HTML）**: http://localhost:8080/users/123
- **用户列表（JSON）**: http://localhost:8080/api/users
- **用户详情（JSON）**: http://localhost:8080/api/users/123

## 📝 代码结构

### 主应用入口 (`main.mbt`)

```moonbit
fn main {
  // 1. 创建 IoC 容器
  let config = [...]
  let ctx = @ApplicationContext.ApplicationContext::new(config, "com.example")
  
  // 2. 注册 Bean
  ctx.register_bean("userService", "com.example.service.UserService", 10, false)
  
  // 3. 创建 Controller
  let user_controller = @Controller.Controller::new("/users")
    .get("/", fn(request) { ... })
  
  // 4. 创建 DispatcherServlet
  let dispatcher = @Dispatcher.DispatcherServlet::new()
    .register_controller("userController", user_controller)
  
  // 5. 启动应用
  @Boot.BootApplication::run(8080, fn() { dispatcher })
}
```

## 🌐 可用端点

### HTML 端点（Controller）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/` | 首页 |
| GET | `/users` | 用户列表 |
| GET | `/users/{id}` | 用户详情 |
| POST | `/users` | 创建用户 |
| PUT | `/users/{id}` | 更新用户 |
| DELETE | `/users/{id}` | 删除用户 |

### JSON 端点（RestController）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/users` | 用户列表（JSON） |
| GET | `/api/users/{id}` | 用户详情（JSON） |
| POST | `/api/users` | 创建用户（JSON） |
| PUT | `/api/users/{id}` | 更新用户（JSON） |
| DELETE | `/api/users/{id}` | 删除用户（JSON） |

### 认证端点（Auth）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/login` | 用户登录 |
| POST | `/api/auth/logout` | 用户登出 |

**登录接口详情**：
- **URL**: `POST /api/auth/login`
- **Content-Type**: `application/json` 或 `application/x-www-form-urlencoded`
- **请求参数**:
  ```json
  {
    "username": "admin",
    "password": "123456"
  }
  ```
- **响应格式**:
  ```json
  {
    "success": "true",
    "message": "登录成功",
    "token": "token_admin_123456"
  }
  ```
- **测试账号**:
  - 用户名: `admin`，密码: `123456`
  - 用户名: `user`，密码: `password`

## 📖 使用示例

### 测试 GET 请求

```bash
# 访问首页
curl http://localhost:8080/

# 获取用户列表（HTML）
curl http://localhost:8080/users

# 获取用户列表（JSON）
curl http://localhost:8080/api/users

# 获取用户详情
curl http://localhost:8080/users/123
curl http://localhost:8080/api/users/123
```

### 测试 POST 请求

```bash
# 创建用户（HTML）
curl -X POST http://localhost:8080/users

# 创建用户（JSON）
curl -X POST http://localhost:8080/api/users
```

### 测试 PUT 请求

```bash
# 更新用户
curl -X PUT http://localhost:8080/users/123
curl -X PUT http://localhost:8080/api/users/123
```

### 测试 DELETE 请求

```bash
# 删除用户
curl -X DELETE http://localhost:8080/users/123
curl -X DELETE http://localhost:8080/api/users/123
```

### 测试登录接口

```bash
# 登录（JSON 格式）
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}'

# 登录（表单格式）
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=123456"

# 登出
curl -X POST http://localhost:8080/api/auth/logout
```

## 🔍 代码说明

### 1. IoC 容器

```moonbit
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
```

### 2. Bean 注册

```moonbit
// 注册 Bean（类似 Spring 的 @Component, @Service, @Repository）
ctx.register_bean("userService", "com.example.service.UserService", 10, false)
ctx.register_bean("userRepository", "com.example.repository.UserRepository", 5, false)
ctx.register_bean("userController", "com.example.controller.UserController", 20, false)

// 创建所有 Bean 实例
ctx.create_all_beans()
```

### 3. Controller 创建

```moonbit
// 创建 Controller（类似 Spring 的 @Controller）
let user_controller = @Controller.Controller::new("/users")
  // GET /users（类似 @GetMapping("/")）
  .get("/", fn(request) {
    let html = "<html>...</html>"
    @Http.HttpResponse::ok(html)
  })
  
  // GET /users/{id}（类似 @GetMapping("/{id}")）
  .get("/{id}", fn(request) {
    let path = request.get_path()
    @Http.HttpResponse::ok("<h1>用户详情</h1>")
  })
  
  // POST /users（类似 @PostMapping("/")）
  .post("/", fn(request) {
    @Http.HttpResponse::created("<h1>创建成功</h1>")
  })
```

### 4. RestController 创建

```moonbit
// 创建 RestController（类似 Spring 的 @RestController）
let api_controller = @Controller.RestController::new("/api/users")
  // GET /api/users（类似 @GetMapping("/")）
  .get("/", fn(request) {
    let data = @hashmap.new()
    data.set("id", "1")
    data.set("name", "Alice")
    data.set("email", "alice@example.com")
    @Controller.JsonResponse::new(data)
  })
```

### 5. DispatcherServlet 配置

```moonbit
// 创建 DispatcherServlet（类似 Spring MVC 的 DispatcherServlet）
let dispatcher = @Dispatcher.DispatcherServlet::new()
  .register_controller("rootController", root_controller)
  .register_controller("userController", user_controller)
  .register_rest_controller("apiController", api_controller)
```

### 6. 启动应用

```moonbit
// 使用 BootApplication 启动应用（类似 Spring Boot 的 @SpringBootApplication）
@Boot.BootApplication::run(8080, fn() {
  dispatcher
})
```

## 🎯 与 Spring Boot 对比

| 功能 | Spring Boot | Autumn Frame |
|------|------------|--------------|
| **IoC 容器** | `@SpringBootApplication` | `ApplicationContext::new()` |
| **Bean 注册** | `@Component`, `@Service` | `ctx.register_bean()` |
| **Controller** | `@Controller`, `@GetMapping` | `Controller::new()`, `.get()` |
| **RestController** | `@RestController`, `@GetMapping` | `RestController::new()`, `.get()` |
| **启动应用** | `SpringApplication.run()` | `BootApplication::run()` |

## 🌐 CORS 支持

### 自动 CORS 配置

Autumn Frame 后端已自动添加 CORS 支持，所有响应都会自动包含以下响应头：

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Max-Age: 3600
```

### 说明

- ✅ **自动处理 OPTIONS 预检请求**：浏览器发送的 OPTIONS 请求会自动响应
- ✅ **所有响应都包含 CORS 头**：包括成功响应和错误响应（404、500 等）
- ✅ **默认允许所有域名访问**：`Access-Control-Allow-Origin: *`
- ⚠️ **生产环境建议**：修改为具体的域名以提高安全性

### 前端对接

前端可以直接调用后端接口，无需担心 CORS 问题：

```javascript
// 前端可以直接调用后端接口
fetch('http://localhost:8080/api/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    username: 'admin',
    password: '123456'
  })
})
.then(response => response.json())
.then(data => {
  if (data.success === 'true') {
    console.log('登录成功', data.token);
    localStorage.setItem('token', data.token);
  }
});
```

## 📚 相关文档

- [使用指南](../使用指南.md) - 完整的使用文档
- [后端对接文档](../后端对接文档.md) - Next.js 前端与后端对接文档
- [登录接口对接文档](./登录接口对接文档.md) - 详细的登录接口说明
- [Autumn Frame 项目结构](../autumn-frame/) - 框架源码

## 🔐 认证功能

### 登录模块 (`auth.mbt`)

示例包含完整的登录认证功能：

1. **解析请求数据**：支持 JSON 和表单格式
2. **用户验证**：验证用户名和密码
3. **Token 生成**：登录成功后生成 Token
4. **错误处理**：处理各种错误情况

### 测试账号

系统提供了以下测试账号：

| 用户名 | 密码 | 说明 |
|--------|------|------|
| admin | 123456 | 管理员账号 |
| user | password | 普通用户账号 |

### 前端对接示例

详细的前端对接示例请查看：
- [登录接口对接文档](./登录接口对接文档.md)
- [后端对接文档](../后端对接文档.md)

## 🎉 总结

这个示例完整展示了 Autumn Frame 的使用方式，包括：

1. ✅ IoC 容器的创建和配置
2. ✅ Bean 的注册和管理
3. ✅ Controller 和 RestController 的创建
4. ✅ DispatcherServlet 的配置
5. ✅ 应用的启动和运行
6. ✅ 登录认证功能
7. ✅ CORS 自动支持

通过这个示例，你可以快速了解 Autumn Frame 的核心功能和使用方式，并可以直接用于前端项目对接。
