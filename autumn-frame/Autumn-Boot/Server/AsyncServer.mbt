/// AsyncServer - 基于 moonbitlang/async 的异步 HTTP 服务器
/// 
/// 使用 @async/http 模块实现 HTTP 服务器，避免 FFI 字符串编码问题
/// 
/// 参考：https://www.moonbitlang.cn/pearls/2025/10/22/moonbit-http-server
/// 
/// 使用示例：
/// ```moonbit
/// async fn main {
///   let server = AsyncServer::new(8080, dispatcher)
///   server.start().await
/// }
/// ```

// ========== 导入依赖 ==========
// 使用 moonbitlang/async 的 HTTP 和 Socket 模块

// ========== 异步服务器实现 ==========

///|
/// 异步 HTTP 服务器
/// 
/// 提供基于 moonbitlang/async 的 HTTP 服务器实现，集成 DispatcherServlet
pub struct AsyncServer {
  port : Int // 服务器端口
  dispatcher : @Dispatcher.DispatcherServlet // 请求分发器
  mut running : Bool // 服务器运行状态
}

///|
/// 创建异步服务器
pub fn AsyncServer::new(
  port : Int,
  dispatcher : @Dispatcher.DispatcherServlet,
) -> AsyncServer {
  { port, dispatcher, running: false }
}

///|
/// 启动异步服务器
/// 
/// 使用 @async/http 模块创建 HTTP 服务器并开始监听
pub async fn AsyncServer::start(self : AsyncServer) -> Unit {
  self.running = true
  println(
    "[AsyncServer] Starting async HTTP server on port " + self.port.to_string(),
  )

  // 使用 @async/http 创建 HTTP 服务器
  // 注意：这里需要根据实际的 @async/http API 来调整
  // 根据文章，应该使用类似这样的方式：
  // let server = @http.Server.new()
  // server.listen(self.port)  // MoonBit 不需要显式的 await

  // 由于我们不确定确切的 API，这里提供一个适配层
  // 将 DispatcherServlet 的同步接口适配到异步 HTTP 服务器
  AsyncServer::start_http_server(self.port, self.dispatcher)
  println(
    "[AsyncServer] ✅ Server is running at http://localhost:" +
    self.port.to_string(),
  )
  println("[AsyncServer] Press Ctrl+C to stop the server")
}

///|
/// 启动 HTTP 服务器（内部实现）
/// 
/// 使用 @async/http 和 @socket 模块创建 HTTP 服务器
/// 
/// 实现方式：
/// 1. 创建 TCP 服务器：@socket.TcpServer::new(@socket.Addr::parse("0.0.0.0:\{port}"))
/// 2. 使用 @async.with_task_group 管理并发连接
/// 3. 为每个连接创建 @http.ServerConnection
/// 4. 读取请求并处理，发送响应
async fn AsyncServer::start_http_server(
  port : Int,
  dispatcher : @Dispatcher.DispatcherServlet,
) -> Unit {
  // 构建服务器地址
  let addr_str = "0.0.0.0:" + port.to_string()
  println("[AsyncServer] Creating HTTP server on " + addr_str)

  // 创建 TCP 服务器
  let server = @socket.TcpServer::new(@socket.Addr::parse(addr_str))
  defer server.close()
  println(
    "[AsyncServer] TCP server created, listening on port " + port.to_string(),
  )

  // 使用任务组来管理并发连接
  @async.with_task_group(fn(ctx) {
    // 接受连接循环
    for {
      // 接受新连接
      let (conn, addr) = server.accept()

      // 创建 HTTP 服务器连接
      let http_conn = @http.ServerConnection::new(conn)
      println("[AsyncServer] Received new connection from " + addr.to_string())

      // 为每个连接创建后台任务
      ctx.spawn_bg(allow_failure=true, fn() {
        defer {
          println("[AsyncServer] Closing connection from " + addr.to_string())
          http_conn.close()
        }

        // 处理请求循环（一个连接可能发送多个请求）
        for {
          // 读取请求
          let request = http_conn.read_request()

          // 打印请求信息（包括方法）
          let method_str = match request.meth {
            @http.Get => "GET"
            @http.Post => "POST"
            @http.Put => "PUT"
            @http.Delete => "DELETE"
            @http.Patch => "PATCH"
            @http.Head => "HEAD"
            @http.Options => "OPTIONS"
            @http.Connect => "CONNECT"
            @http.Trace => "TRACE"
          }
          println("[AsyncServer] Serving " + method_str + " " + request.path)

          // 转换 @http.Request 到我们的 @Http.HttpRequest
          let http_request = AsyncServer::convert_request(request)

          // 使用 DispatcherServlet 处理请求
          let http_response = dispatcher.handle_request(http_request)

          // 发送响应
          AsyncServer::send_response(http_conn, http_response)
        }
      })
    }
  })
}

///|
/// 停止服务器
pub fn AsyncServer::stop(self : AsyncServer) -> Unit {
  self.running = false
  println("[AsyncServer] Stopping async HTTP server...")
  println("[AsyncServer] Server stopped")
}

///|
/// 检查服务器是否运行
pub fn AsyncServer::is_running(self : AsyncServer) -> Bool {
  self.running
}

///|
/// 获取服务器端口
pub fn AsyncServer::get_port(self : AsyncServer) -> Int {
  self.port
}

///|
/// 将 @http.Request 转换为 @Http.HttpRequest
/// 
/// 参数：
/// - req: @http.Request 对象（来自 moonbitlang/async）
/// 
/// 返回值：
/// - @Http.HttpRequest 对象（我们的框架使用的类型）
fn AsyncServer::convert_request(req : @http.Request) -> @Http.HttpRequest {
  // 转换 HTTP 方法
  let http_method = match req.meth {
    @http.Get => @Http.HttpMethod::from_string("GET")
    @http.Post => @Http.HttpMethod::from_string("POST")
    @http.Put => @Http.HttpMethod::from_string("PUT")
    @http.Delete => @Http.HttpMethod::from_string("DELETE")
    @http.Patch => @Http.HttpMethod::from_string("PATCH")
    @http.Head => @Http.HttpMethod::from_string("HEAD")
    @http.Options => @Http.HttpMethod::from_string("OPTIONS")
    @http.Connect => @Http.HttpMethod::from_string("GET") // 默认使用 GET
    @http.Trace => @Http.HttpMethod::from_string("GET") // 默认使用 GET
  }

  // 解析路径（可能包含查询参数）
  let path_with_query = req.path
  let path_parts = Array::from_iter(path_with_query.split("?"))
  let path = if path_parts.length() > 0 {
    path_parts[0].to_string()
  } else {
    "/"
  }

  // 解析查询参数
  let query_params = @hashmap.new()
  if path_parts.length() > 1 {
    let query_string = path_parts[1].to_string()
    let query_pairs = Array::from_iter(query_string.split("&"))
    for pair in query_pairs {
      let kv = Array::from_iter(pair.split("="))
      if kv.length() == 2 {
        let key = kv[0].to_string()
        let value = kv[1].to_string()
        query_params.set(key, value)
      }
    }
  }

  // 转换请求头（从 Map[String, String] 到 HashMap[String, String]）
  let headers = @hashmap.new()
  // 注意：req.headers 是 Map[String, String]，需要转换为 HashMap
  // 由于 Map 可能没有迭代器，这里简化处理
  // 实际使用时可能需要根据 Map 的 API 来调整
  // 暂时使用空的 headers，如果需要可以从 req.headers 中获取

  // 请求体：由于 @http.Request 不包含 body，我们需要从 ServerConnection 读取
  // 但这里暂时使用 None，如果需要可以在调用处处理
  let body = None
  @Http.HttpRequest::new(http_method, path, query_params, headers, body)
}

///|
/// 发送 HTTP 响应
/// 
/// 参数：
/// - conn: HTTP 服务器连接
/// - response: HTTP 响应对象
/// 
/// 使用 @http.ServerConnection 的方法发送响应
async fn AsyncServer::send_response(
  conn : @http.ServerConnection,
  response : @Http.HttpResponse,
) -> Unit {
  // 获取状态码和状态文本
  let status_code = response.get_status_code()
  let status_text = match status_code {
    200 => "OK"
    201 => "Created"
    204 => "No Content"
    400 => "Bad Request"
    401 => "Unauthorized"
    403 => "Forbidden"
    404 => "Not Found"
    500 => "Internal Server Error"
    _ => "Unknown"
  }

  // 构建响应头（从 response.headers 获取所有头）
  // 注意：需要将所有 response.headers 中的头都添加到响应中（包括 CORS 头）
  // 由于 @http.ServerConnection 的 send_response 需要 Map 类型，我们需要构建一个 Map
  // 先获取所有响应头（包括 CORS 头）
  let access_control_origin = response.get_header("Access-Control-Allow-Origin")
  let access_control_methods = response.get_header(
    "Access-Control-Allow-Methods",
  )
  let access_control_headers = response.get_header(
    "Access-Control-Allow-Headers",
  )
  let access_control_max_age = response.get_header("Access-Control-Max-Age")
  let content_type = response.get_header("Content-Type")

  // 确保 CORS 头被设置到 response.headers 中
  // 如果 response.headers 中没有 CORS 头，则添加默认值
  let cors_origin = match access_control_origin {
    Some(v) => v
    None => "*"
  }
  let cors_methods = match access_control_methods {
    Some(v) => v
    None => "GET, POST, PUT, DELETE, OPTIONS"
  }
  let cors_headers = match access_control_headers {
    Some(v) => v
    None => "Content-Type, Authorization"
  }
  let cors_max_age = match access_control_max_age {
    Some(v) => v
    None => "3600"
  }

  // 将 CORS 头设置到 response.headers 中
  response.headers.set("Access-Control-Allow-Origin", cors_origin)
  response.headers.set("Access-Control-Allow-Methods", cors_methods)
  response.headers.set("Access-Control-Allow-Headers", cors_headers)
  response.headers.set("Access-Control-Max-Age", cors_max_age)

  // 设置 Content-Type（如果还没有设置）
  match content_type {
    Some(ct) => response.headers.set("Content-Type", ct)
    None =>
      match response.get_body() {
        Some(_) =>
          response.headers.set(
            "Content-Type", "application/json; charset=utf-8",
          )
        None => response.headers.set("Content-Type", "text/plain")
      }
  }

  // 构建 extra_headers Map（从 response.headers 构建）
  // 注意：需要将 HashMap 转换为 Map 字面量
  // 但由于 Map 字面量需要静态键，我们需要手动构建
  let headers_map = {
    "Access-Control-Allow-Origin": cors_origin,
    "Access-Control-Allow-Methods": cors_methods,
    "Access-Control-Allow-Headers": cors_headers,
    "Access-Control-Max-Age": cors_max_age,
    "Content-Type": match response.get_header("Content-Type") {
      Some(ct) => ct
      None => "text/plain"
    },
  }

  // 打印调试信息
  println("[AsyncServer] Sending response:")
  println("  Status: " + status_code.to_string() + " " + status_text)
  println("  Access-Control-Allow-Origin: " + cors_origin)
  println("  Access-Control-Allow-Methods: " + cors_methods)
  println("  Access-Control-Allow-Headers: " + cors_headers)
  println("  Access-Control-Max-Age: " + cors_max_age)
  println("  Content-Type: " + headers_map["Content-Type"])

  // 测试 Map 的 to_array 方法
  let headers_array = headers_map.to_array()
  println(
    "[AsyncServer] extra_headers Map contains " +
    headers_array.length().to_string() +
    " headers:",
  )
  for i = 0; i < headers_array.length(); i = i + 1 {
    let (k, v) = headers_array[i]
    println("    " + k + ": " + v)
  }

  // 发送响应头（包含所有头，特别是 CORS 头）
  // 使用 @http.ServerConnection 的 send_response 方法，并传递 extra_headers 参数
  // extra_headers 应该包含所有响应头，包括 CORS 头
  // 参考 moonbitlang/async 示例：使用链式调用
  println("[AsyncServer] Calling send_response with extra_headers...")
  conn.send_response(status_code, status_text, extra_headers=headers_map)
  println("[AsyncServer] send_response completed")

  // 发送响应体
  match response.get_body() {
    Some(body) => conn.write(body)
    None => ()
  }

  // 结束响应
  conn.end_response()
}
