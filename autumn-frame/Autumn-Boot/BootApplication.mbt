/// BootApplication - 启动类
/// 
/// 类似于 Spring Boot 的 @SpringBootApplication，提供应用启动功能
/// 
/// 使用示例：
/// ```moonbit
/// fn main {
///   BootApplication::run(8080, fn() {
///     // 配置 DispatcherServlet
///     let dispatcher = DispatcherServlet::new()
///       .register_controller("userController", user_controller)
///     dispatcher
///   })
/// }
/// ```

// ========== 导入依赖 ==========

// ========== 启动类 ==========

///|
/// BootApplication - 启动类
/// 
/// 提供应用启动功能，类似于 Spring Boot 的 @SpringBootApplication
pub struct BootApplication {
  port : Int // 服务器端口
  dispatcher_factory : () -> @Dispatcher.DispatcherServlet // DispatcherServlet 工厂函数
}

///|
/// 创建 BootApplication
pub fn BootApplication::new(
  port : Int,
  dispatcher_factory : () -> @Dispatcher.DispatcherServlet,
) -> BootApplication {
  { port, dispatcher_factory }
}

///|
/// 运行应用
/// 
/// 创建并启动嵌入式服务器
/// 
/// 参数：
/// - port: 服务器端口
/// - dispatcher_factory: DispatcherServlet 工厂函数
pub fn BootApplication::run(
  port : Int,
  dispatcher_factory : () -> @Dispatcher.DispatcherServlet,
) -> Unit {
  println("[Boot] Starting Autumn Boot application...")

  // 1. 创建 DispatcherServlet
  let dispatcher = dispatcher_factory()

  // 2. 创建嵌入式服务器
  let server = @Server.EmbeddedServer::new(port, dispatcher)

  // 3. 启动服务器
  server.start()
  println("[Boot] Application started successfully!")
  println("[Boot] Server is running at http://localhost:" + port.to_string())
  println("[Boot] Press Ctrl+C to stop the server")

  // 注意：实际服务器启动需要 FFI 调用或使用事件循环
  // 这里提供一个占位实现，实际使用时需要：
  // 1. 使用 FFI 调用 Node.js 的 http 模块创建服务器
  // 2. 或者使用其他 WebAssembly 运行时提供的 HTTP 服务器 API
  // 3. 或者提供一个简单的 HTTP 服务器实现
}

///|
/// 运行应用（使用默认配置）
/// 
/// 使用默认端口 8080 启动应用
/// 
/// 参数：
/// - dispatcher_factory: DispatcherServlet 工厂函数
pub fn BootApplication::run_default(
  dispatcher_factory : () -> @Dispatcher.DispatcherServlet,
) -> Unit {
  BootApplication::run(8080, dispatcher_factory)
}

///|
/// 运行应用（使用配置对象）
/// 
/// 参数：
/// - config: 应用配置
pub fn BootApplication::run_with_config(config : BootApplicationConfig) -> Unit {
  BootApplication::run(config.port, config.dispatcher_factory)
}

///|
/// 应用配置
pub struct BootApplicationConfig {
  port : Int // 服务器端口
  dispatcher_factory : () -> @Dispatcher.DispatcherServlet // DispatcherServlet 工厂函数
}

///|
/// 创建应用配置
pub fn BootApplicationConfig::new(
  port : Int,
  dispatcher_factory : () -> @Dispatcher.DispatcherServlet,
) -> BootApplicationConfig {
  { port, dispatcher_factory }
}

///|
/// 创建应用配置（使用默认端口）
pub fn BootApplicationConfig::with_default_port(
  dispatcher_factory : () -> @Dispatcher.DispatcherServlet,
) -> BootApplicationConfig {
  BootApplicationConfig::new(8080, dispatcher_factory)
}
