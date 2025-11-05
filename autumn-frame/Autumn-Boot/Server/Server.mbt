/// Server - 服务器接口
/// 
/// 定义嵌入式 HTTP 服务器的接口
/// 
/// 使用示例：
/// ```moonbit
/// let server = EmbeddedServer::new(8080, dispatcher)
/// server.start()
/// ```

// ========== 导入依赖 ==========

// FFI 函数声明（仅 native 后端）
/// 创建 TCP socket 并绑定端口
/// 返回值：socket 文件描述符，失败返回 -1
#borrow(port)
pub extern "C" fn autumn_create_server_socket(port : Int) -> Int = "autumn_create_server_socket"

/// 接受连接
/// 返回值：客户端 socket 文件描述符，失败返回 -1
#borrow(server_fd)
pub extern "C" fn autumn_accept_connection(server_fd : Int) -> Int = "autumn_accept_connection"

/// 读取请求到静态缓冲区（简化版，读取最多 4096 字节）
/// 返回值：读取的字节数，失败返回 -1
#borrow(client_fd)
pub extern "C" fn autumn_read_request(client_fd : Int) -> Int = "autumn_read_request"

/// 获取读取的请求数据（从静态缓冲区）
/// 返回值：指向请求数据的 C 字符串指针
pub extern "C" fn autumn_get_request_buffer() -> String = "autumn_get_request_buffer"

/// 获取读取的字节数
pub extern "C" fn autumn_get_request_length() -> Int = "autumn_get_request_length"

/// 发送响应
/// 返回值：发送的字节数，失败返回 -1
#borrow(response)
pub extern "C" fn autumn_send_response(client_fd : Int, response : String, response_len : Int) -> Int = "autumn_send_response"

/// 关闭连接
#borrow(fd)
pub extern "C" fn autumn_close_connection(fd : Int) -> Unit = "autumn_close_connection"

/// 关闭服务器
#borrow(server_fd)
pub extern "C" fn autumn_close_server(server_fd : Int) -> Unit = "autumn_close_server"

// ========== 服务器接口 ==========

/// 服务器接口
pub trait Server {
  /// 启动服务器
  start(Self) -> Unit
  
  /// 停止服务器
  stop(Self) -> Unit
  
  /// 检查服务器是否运行
  is_running(Self) -> Bool
  
  /// 获取服务器端口
  get_port(Self) -> Int
}

// ========== 嵌入式服务器 ==========

/// 嵌入式 HTTP 服务器
/// 
/// 提供简单的 HTTP 服务器实现，集成 DispatcherServlet
pub struct EmbeddedServer {
  port : Int  // 服务器端口
  dispatcher : @Dispatcher.DispatcherServlet  // 请求分发器
  mut running : Bool  // 服务器运行状态
}

/// 创建嵌入式服务器
pub fn EmbeddedServer::new(
  port : Int,
  dispatcher : @Dispatcher.DispatcherServlet
) -> EmbeddedServer {
  {
    port,
    dispatcher,
    running: false
  }
}

/// 实现 Server 接口
pub impl Server for EmbeddedServer with start(self) {
  self.running = true
  println("[Server] Starting embedded server on port " + self.port.to_string())
  
  // 创建服务器 socket
  let server_fd = autumn_create_server_socket(self.port)
  
  if server_fd < 0 {
    println("[Server] ❌ Failed to create server socket on port " + self.port.to_string())
    self.running = false
  } else {
    println("[Server] ✅ Server is running at http://localhost:" + self.port.to_string())
    println("[Server] Press Ctrl+C to stop the server")
    
    // 事件循环：接受连接并处理请求
    while self.running {
      // 接受连接（accept 会阻塞直到有连接）
      let client_fd = autumn_accept_connection(server_fd)
      
      if client_fd >= 0 {
        // 读取 HTTP 请求到静态缓冲区
        let bytes_read = autumn_read_request(client_fd)
        
        if bytes_read > 0 {
          // 从静态缓冲区获取请求数据
          let buffer = autumn_get_request_buffer()
          
          // 解析请求
          match EmbeddedServer::parse_request(buffer) {
            Some(request) => {
              // 使用 DispatcherServlet 处理请求
              let response = self.dispatcher.handle_request(request)
              
              // 格式化响应
              let response_str = EmbeddedServer::format_response(response)
              
              // 发送响应
              let _ = autumn_send_response(client_fd, response_str, response_str.length())
            }
            None => {
              // 解析失败，返回 400 Bad Request
              let error_response = "HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain\r\n\r\nBad Request"
              let _ = autumn_send_response(client_fd, error_response, error_response.length())
            }
          }
        } else {
          // 没有读取到数据，关闭连接
          println("[Server] No data received from client")
        }
        
        // 关闭客户端连接
        autumn_close_connection(client_fd)
      }
    }
    
    // 关闭服务器 socket
    autumn_close_server(server_fd)
    println("[Server] Server stopped")
  }
}

pub impl Server for EmbeddedServer with stop(self) {
  self.running = false
  println("[Server] Stopping embedded server...")
  println("[Server] Server stopped")
}

pub impl Server for EmbeddedServer with is_running(self) {
  self.running
}

pub impl Server for EmbeddedServer with get_port(self) {
  self.port
}

/// 处理 HTTP 请求（内部方法）
/// 
/// 将 HTTP 请求转换为 DispatcherServlet 可以处理的格式
fn EmbeddedServer::handle_http_request(
  self : EmbeddedServer,
  request : @Http.HttpRequest
) -> @Http.HttpResponse {
  // 使用 DispatcherServlet 处理请求
  self.dispatcher.handle_request(request)
}

/// 将 HTTP 请求字符串解析为 HttpRequest 对象
/// 
/// 参数：
/// - raw_request: 原始 HTTP 请求字符串
/// 
/// 返回值：
/// - HttpRequest 对象
pub fn EmbeddedServer::parse_request(raw_request : String) -> @Http.HttpRequest? {
  // 解析 HTTP 请求字符串
  // 格式：GET /path HTTP/1.1\r\nHeader: Value\r\n\r\nBody
  let lines = Array::from_iter(raw_request.split("\r\n"))
  
  if lines.length() == 0 {
    None
  } else {
    // 解析请求行
    let request_line = lines[0].to_string()
    let request_parts = Array::from_iter(request_line.split(" "))
    
    if request_parts.length() < 2 {
      None
    } else {
      // 解析 HTTP 方法
      let method_str = request_parts[0].to_string()
      let http_method = @Http.HttpMethod::from_string(method_str)
      
      // 解析路径（可能包含查询参数）
      let path_with_query = request_parts[1].to_string()
      let path_parts = Array::from_iter(path_with_query.split("?"))
      let path = path_parts[0].to_string()
      
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
      
      // 解析请求头
      let headers = @hashmap.new()
      let mut i = 1
      while i < lines.length() {
        let line = lines[i].to_string()
        if line.length() == 0 {
          // 空行，请求头结束
          break
        }
        let header_parts = Array::from_iter(line.split(": "))
        if header_parts.length() == 2 {
          let key = header_parts[0].to_string()
          let value = header_parts[1].to_string()
          headers.set(key, value)
        }
        i = i + 1
      }
      
      // 解析请求体（如果有）
      let body = if i + 1 < lines.length() {
        // 请求体在空行之后
        let mut body_str = ""
        let mut j = i + 1
        while j < lines.length() {
          if body_str.length() > 0 {
            body_str = body_str + "\r\n"
          }
          body_str = body_str + lines[j].to_string()
          j = j + 1
        }
        if body_str.length() > 0 {
          Some(body_str)
        } else {
          None
        }
      } else {
        None
      }
      
      Some(@Http.HttpRequest::new(http_method, path, query_params, headers, body))
    }
  }
}

/// 将 HttpResponse 对象转换为 HTTP 响应字符串
/// 
/// 参数：
/// - response: HttpResponse 对象
/// 
/// 返回值：
/// - HTTP 响应字符串
pub fn EmbeddedServer::format_response(response : @Http.HttpResponse) -> String {
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
  
  // 构建响应行
  let mut response_str = "HTTP/1.1 " + status_code.to_string() + " " + status_text + "\r\n"
  
  // 添加响应头
  // 注意：HttpResponse 没有提供获取所有头的方法，这里简化实现
  response_str = response_str + "Content-Type: text/html; charset=utf-8\r\n"
  
  // 添加响应体
  match response.get_body() {
    Some(body) => {
      response_str = response_str + "Content-Length: " + body.length().to_string() + "\r\n"
      response_str = response_str + "\r\n"
      response_str = response_str + body
    }
    None => {
      response_str = response_str + "\r\n"
    }
  }
  
  response_str
}

