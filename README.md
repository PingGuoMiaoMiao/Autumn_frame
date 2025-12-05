# 🍂 Autumn Frame

<div align="center">


[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![MoonBit](https://img.shields.io/badge/MoonBit-0.4.34-orange.svg)](https://www.moonbitlang.com/)
[![Version](https://img.shields.io/badge/version-0.1.0-green.svg)](https://github.com/PingGuoMiaoMiao/Autumn_frame)

[快速开始](#-快速开始) • [特性](#-核心特性) • [文档](#-文档) • [示例](#-示例项目) • [贡献](#-参与贡献)

</div>

---

## 🌟 这是什么？

如果你写过 Spring Boot，就能立刻看懂 Autumn。它是用 **MoonBit** 搭的 Spring 风格 Web 框架：IoC、WebMVC、AOP、JDBC、Boot 一条龙。静态编译成原生二进制，`moon run` 一键起服务，不和 JVM 打交道。

```moonbit
fn main {
  let ctx = @ApplicationContext.ApplicationContext::new(config, "demo")
  
  let hello = @Controller.RestController::new("/hello")
    .get("/", fn(_) {
      let data = @hashmap.new()
      data.set("message", "Hello, Autumn! 🍂")
      @Controller.JsonResponse::new(data)
    })
  
  let dispatcher = @Dispatcher.DispatcherServlet::new()
    .register_rest_controller("hello", hello)
  
  println("🚀 服务器启动在 http://localhost:8080")
  @Boot.BootApplication::run(8080, fn() { dispatcher })
}
```

就这些。没有魔法，没有黑箱，只有 MoonBit + 一堆手撸的模块。

---

## ✨ 核心特性

### 🎯 熟悉的开发体验

- **IoC 容器**：像 Spring 一样管理你的 Bean
- **依赖注入**：自动装配，解耦合
- **MVC 架构**：Controller、Service、Repository，该有的都有
- **RESTful API**：一行代码定义一个接口
- **配置驱动**：类似 `application.properties` 的配置方式

### ⚙️ 提供的模块

- **Autumn-IoC**：Bean 定义、注册、依赖注入、生命周期。
- **Autumn-WebMVC**：`Controller/RestController`、Dispatcher、Http 抽象、统一异常。
- **Autumn-AOP**：Pointcut + Advice + Proxy，自定义拦截链。
- **Autumn-JDBC**：JdbcTemplate + 多数据源实现（内存/SQLite/MySQL/PostgreSQL）。
- **Autumn-Boot**：嵌入式 HTTP Server（C FFI），自动 CORS。

### 性能与部署

- 原生二进制，`moon run --target native` 直接生成可执行文件。
- 启动时间短（毫秒级），默认单进程单线程，方便外挂 systemd / supervisor。
- 依赖 `gcc` + 对应数据库库（`libmysqlclient`、`libsqlite3`、`libpq`）。

---

## 🚀 快速开始

### 安装 MoonBit

```bash
# 安装 MoonBit 工具链
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
```

### 创建你的第一个项目

```bash
# 创建新项目
moon new my-autumn-app
cd my-autumn-app

# 添加 Autumn Frame 依赖
moon add PingGuoMiaoMiao/Autumn_frame
```

### 编写代码

创建 `main.mbt`：

```moonbit
fn main {
  // 1. 配置应用
  let config = [
    ("app.name", "My First Autumn App"),
    ("server.port", "8080")
  ]
  
  // 2. 创建 IoC 容器
  let ctx = @ApplicationContext.ApplicationContext::new(config, "demo")
  
  // 3. 定义 REST 控制器
  let api = @Controller.RestController::new("/api")
    .get("/hello", fn(_) {
      let resp = @hashmap.new()
      resp.set("message", "Hello from Autumn! 🍂")
      resp.set("timestamp", @time.now().to_string())
      @Controller.JsonResponse::new(resp)
    })
    .get("/users", fn(_) {
      let resp = @hashmap.new()
      resp.set("users", "[{\"id\":1,\"name\":\"Alice\"},{\"id\":2,\"name\":\"Bob\"}]")
      @Controller.JsonResponse::new(resp)
    })
  
  // 4. 注册路由
  let dispatcher = @Dispatcher.DispatcherServlet::new()
    .register_rest_controller("api", api)
  
  // 5. 启动服务器
  println("🚀 Autumn 应用启动在 http://localhost:8080")
  println("📝 试试访问 http://localhost:8080/api/hello")
  @Boot.BootApplication::run(8080, fn() { dispatcher })
}
```

### 运行应用

```bash
# 编译并运行（原生模式）
moon run --target native

# 或者先构建再运行
moon build --target native
./target/native/release/build/main/main
```

访问 `http://localhost:8080/api/hello`，你会看到：

```json
{
  "message": "Hello from Autumn! 🍂",
  "timestamp": "2024-12-01T12:00:00Z"
}
```

至此就能在浏览器里看到 JSON 了，接下来随便改。

---

### 🧭 运行本仓库的示例项目

> 仓库里的 demo 在 `moon.pkg.json` 里直接写了 `$PWD/.../*.o`。**一定要 `cd` 到 demo 目录再执行 `moon run --target native main.mbt`**，否则链接命令里 `$PWD` 不会展开，会直接报“找不到 `$PWD/...`”。

- `autumn-demo`（视频社区 + MariaDB 示例）
  ```bash
  cd /home/pingguomiaomiao/Desktop/Autumn_frame/autumn-demo
  moon run --target native main.mbt
  ```
- `mysql-demo`（MySQL 数据源示例）
  ```bash
  cd /home/pingguomiaomiao/Desktop/Autumn_frame/mysql-demo
  moon run --target native main.mbt
  ```
- `ffi-demo`（SQLite FFI 示例）
  ```bash
  cd /home/pingguomiaomiao/Desktop/Autumn_frame/ffi-demo
  moon run --target native main.mbt
  ```

想在仓库根目录一把梭？那就先进各 demo 跑一遍 `moon build --target native` 把 `.o` 生成好，不然 `moon` 会顺手帮你编 demo，结果卡在链接阶段。

---

## 📚 文档

### 核心概念

#### 🏗️ IoC 容器

像 Spring 一样，Autumn 使用 IoC 容器管理对象的生命周期：

```moonbit
// 创建容器
let ctx = @ApplicationContext.ApplicationContext::new(config, "com.example")

// 注册 Bean
ctx.register_bean("userService", "com.example.service.UserService", 10, false)
ctx.register_bean("userRepo", "com.example.repository.UserRepository", 5, false)

// 创建所有 Bean
ctx.create_all_beans()

// 获取 Bean
let user_service = ctx.get_required_bean("userService")
```

#### 🌐 Web 控制器

两种控制器，两种风格：

**Controller**：返回 HTML

```moonbit
let page_controller = @Controller.Controller::new("/pages")
  .get("/home", fn(_) {
    @Http.HttpResponse::ok("<h1>欢迎来到 Autumn</h1>")
  })
```

**RestController**：返回 JSON

```moonbit
let api_controller = @Controller.RestController::new("/api/users")
  .get("/", fn(_) {
    // 返回用户列表
    let data = @hashmap.new()
    data.set("users", "[...]")
    @Controller.JsonResponse::new(data)
  })
  .post("/", fn(req) {
    // 创建用户
    let params = parse_request_params(req)
    // ... 处理逻辑
  })
  .put("/{id}", fn(req) {
    // 更新用户
    let id = extract_path_id(req.get_path())
    // ... 处理逻辑
  })
  .delete("/{id}", fn(req) {
    // 删除用户
    let id = extract_path_id(req.get_path())
    // ... 处理逻辑
  })
```

#### 🗄️ 数据库访问

使用 JDBC Template 访问数据库：

```moonbit
// 配置数据源
let db_config = @JdbcTemplate.MySQLDataSourceConfig::new(
  "localhost",
  "3306",
  "root",
  "password",
  "mydb"
)

// 创建连接
let data_source = @JdbcTemplate.MySQLDataSource::new(db_config)
let conn = data_source.connect()

// 执行查询
let sql = "SELECT * FROM users WHERE id = ?"
match conn.query(sql) {
  Some(result) => println("查询成功: " + result)
  None => println("查询失败")
}

// 执行更新
let insert_sql = "INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com')"
match conn.execute(insert_sql) {
  Some(_) => println("插入成功")
  None => println("插入失败")
}
```

支持的数据库：
- ✅ MySQL / MariaDB
- ✅ PostgreSQL
- ✅ SQLite

#### 🎭 AOP 切面

在不修改原代码的情况下，增强功能：

```moonbit
// 定义切点
let pointcut = @AOP.Pointcut::method_match("com.example.service.*", "*")

// 定义通知
let advice = @AOP.Advice::around(pointcut, fn(invocation) {
  println("方法调用前")
  let start = @time.now()
  
  let result = invocation.proceed()
  
  let duration = @time.now() - start
  println("方法调用后，耗时: " + duration.to_string() + "ms")
  
  result
})

// 注册切面
@AOP.AspectRegistry::register(advice)
```

---

## 🎨 示例项目

### 📦 autumn-demo

完整的示例项目，展示所有功能：

```bash
cd autumn-demo
moon run --target native
```

包含：
- ✅ 用户管理 CRUD
- ✅ 认证登录（JWT Token）
- ✅ 数据库集成（MariaDB）
- ✅ RESTful API
- ✅ CORS 支持
- ✅ 错误处理

访问 `http://localhost:8080` 查看所有接口。

### 🗄️ mysql-demo

数据库连接示例：

```bash
cd mysql-demo
moon run --target native
```

展示如何：
- 连接 MySQL/MariaDB
- 执行 SQL 查询
- 处理结果集
- 错误处理

### 🚀 boot-demo

最小化启动示例：

```bash
cd boot-demo
moon run --target native
```

只有 50 行代码，展示最简单的 HTTP 服务器。

---

## 🏗️ 项目结构

```
Autumn_frame/
├── autumn-frame/          # 框架核心代码
│   ├── Autumn-IoC/        # IoC 容器
│   ├── Autumn-WebMVC/     # Web MVC 框架
│   ├── Autumn-AOP/        # AOP 切面
│   ├── Autumn-JDBC/       # 数据库访问
│   └── Autumn-Boot/       # 启动器和服务器
├── autumn-demo/           # 完整示例项目
├── mysql-demo/            # 数据库示例
├── boot-demo/             # 最小化示例
├── 使用指南.md            # 详细使用文档
└── README.md             # 本文件
```

---

## 🎯 与 Spring Boot 对比

| 特性 | Spring Boot | Autumn Frame |
|------|-------------|--------------|
| **语言** | Java | MoonBit |
| **运行时** | JVM | 原生二进制 |
| **启动时间** | 秒级 | 毫秒级 |
| **内存占用** | 100MB+ | 10MB- |
| **IoC 容器** | ✅ | ✅ |
| **依赖注入** | ✅ | ✅ |
| **MVC 架构** | ✅ | ✅ |
| **AOP 支持** | ✅ | ✅ |
| **数据库访问** | JPA/JDBC | JDBC Template |
| **配置方式** | properties/yaml | 键值对数组（规划 TOML） |
| **注解支持** | ✅ | 函数式 API（规划注解） |
| **生态系统** | 成熟完善 | 快速发展中 |

---

## 🛣️ 路线图

### v0.2.0（进行中）
- [ ] 注解语法支持（等待 MoonBit 语言支持）
- [ ] TOML/YAML 配置文件
- [ ] 自动 Bean 扫描
- [ ] 更完善的异常处理

### v0.3.0（规划中）
- [ ] 声明式事务管理
- [ ] 模板引擎集成
- [ ] 静态资源服务
- [ ] WebSocket 支持

### v0.4.0（规划中）
- [ ] 微服务支持（服务发现、负载均衡）
- [ ] 分布式追踪
- [ ] 指标监控
- [ ] 健康检查

### v1.0.0（愿景）
- [ ] 完整的 Spring Boot 功能对等
- [ ] 丰富的中间件生态
- [ ] 生产级稳定性
- [ ] 完善的文档和教程

---

## 🤝 参与贡献

Autumn Frame 是一个开源项目，我们欢迎所有形式的贡献！

### 如何贡献

1. **Fork 这个仓库**
2. **创建你的特性分支** (`git checkout -b feature/amazing-feature`)
3. **提交你的改动** (`git commit -m 'Add some amazing feature'`)
4. **推送到分支** (`git push origin feature/amazing-feature`)
5. **开启一个 Pull Request**

### 贡献方向

- 🐛 **报告 Bug**：发现问题？提个 Issue！
- 💡 **提出建议**：有好想法？我们想听！
- 📝 **改进文档**：文档永远不嫌完善
- 🔧 **修复 Bug**：直接提 PR
- ✨ **添加功能**：实现新特性
- 🌍 **翻译文档**：帮助更多人使用

### 开发环境

```bash
# 克隆仓库
git clone https://github.com/PingGuoMiaoMiao/Autumn_frame.git
cd Autumn_frame

# 安装依赖
moon install

# 运行测试
moon test

# 构建项目
moon build --target native
```

---

## 📖 学习资源

### 官方文档
- [使用指南](./使用指南.md) - 完整的框架使用文档
- [Autumn Demo README](./autumn-demo/README.md) - 示例项目说明
- [前端对接文档](./autumn-demo/前端对接文档.md) - API 对接指南

### MoonBit 资源
- [MoonBit 官网](https://www.moonbitlang.com/)
- [MoonBit 文档](https://docs.moonbitlang.cn/)
- [MoonBit 包管理](https://docs.moonbitlang.cn/language/packages.html)

### 社区
- [GitHub Issues](https://github.com/PingGuoMiaoMiao/Autumn_frame/issues) - 问题反馈
- [GitHub Discussions](https://github.com/PingGuoMiaoMiao/Autumn_frame/discussions) - 讨论交流

---

## 📄 许可证

本项目采用 [Apache-2.0](LICENSE) 许可证。

这意味着你可以：
- ✅ 商业使用
- ✅ 修改代码
- ✅ 分发代码
- ✅ 私有使用
- ✅ 专利授权

只需要：
- 📝 保留版权声明
- 📝 保留许可证声明
- 📝 声明修改内容

---

## 🙏 致谢

感谢以下项目和社区的启发：

- **Spring Framework** - 优雅的设计理念
- **MoonBit** - 强大的语言基础
- 所有为这个项目贡献过的开发者

---

## 💬 联系我们

- **GitHub**: [@PingGuoMiaoMiao](https://github.com/PingGuoMiaoMiao)
- **Email**: 3226742838@qq.com
- **Issues**: [提交问题](https://github.com/PingGuoMiaoMiao/Autumn_frame/issues)

---

<div align="center">

**用 MoonBit 构建下一代 Web 应用** 🍂

如果这个项目对你有帮助，请给个 ⭐️ 吧！

[⬆ 回到顶部](#-autumn-frame)

</div>
