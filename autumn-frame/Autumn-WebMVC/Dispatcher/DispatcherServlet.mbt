/// DispatcherServlet - 核心调度器
/// 
/// 接收所有 URL 请求，然后按 MVC 规则转发到对应的 Controller
/// 
/// 使用示例：
/// ```moonbit
/// let dispatcher = DispatcherServlet::new()
///   .register_controller("userController", user_controller)
///   .register_rest_controller("apiController", api_controller)
/// 
/// let request = HttpRequest::new(GET, "/users/123", @hashmap.new(), @hashmap.new(), None)
/// let response = dispatcher.handle_request(request)
/// ```

// ========== 导入依赖 ==========

/// DispatcherServlet - 核心调度器
pub struct DispatcherServlet {
  controllers : @hashmap.HashMap[String, @Controller.Controller]  // 注册的 Controller
  rest_controllers : @hashmap.HashMap[String, @Controller.RestController]  // 注册的 RestController
  view_resolver : @View.InternalViewResolver?  // 视图解析器（可选）
  filters : Array[@Filter.FilterRegistrationBean]  // 注册的过滤器（按顺序执行）
  exception_handler : @Exception.ExceptionHandler?  // 异常处理器（可选）
}

/// 创建 DispatcherServlet
pub fn DispatcherServlet::new() -> DispatcherServlet {
  {
    controllers: @hashmap.new(),
    rest_controllers: @hashmap.new(),
    view_resolver: None,
    filters: [],
    exception_handler: None
  }
}

/// 注册 Controller
pub fn DispatcherServlet::register_controller(
  self : DispatcherServlet,
  name : String,
  controller : @Controller.Controller
) -> DispatcherServlet {
  self.controllers.set(name, controller)
  self
}

/// 注册 RestController
pub fn DispatcherServlet::register_rest_controller(
  self : DispatcherServlet,
  name : String,
  rest_controller : @Controller.RestController
) -> DispatcherServlet {
  self.rest_controllers.set(name, rest_controller)
  self
}

/// 设置视图解析器
pub fn DispatcherServlet::set_view_resolver(
  self : DispatcherServlet,
  view_resolver : @View.InternalViewResolver
) -> DispatcherServlet {
  { ..self, view_resolver: Some(view_resolver) }
}

/// 注册过滤器
pub fn DispatcherServlet::register_filter(
  self : DispatcherServlet,
  filter_registration : @Filter.FilterRegistrationBean
) -> DispatcherServlet {
  let filters_mut = self.filters
  filters_mut.push(filter_registration)
  // 按 order 排序过滤器
  let sorted_filters = sort_filters_by_order(filters_mut)
  { ..self, filters: sorted_filters }
}

/// 设置异常处理器
pub fn DispatcherServlet::set_exception_handler(
  self : DispatcherServlet,
  exception_handler : @Exception.ExceptionHandler
) -> DispatcherServlet {
  { ..self, exception_handler: Some(exception_handler) }
}

/// 处理 HTTP 请求
/// 
/// 参数：
/// - request: HTTP 请求
/// 
/// 返回值：
/// - HTTP 响应
pub fn DispatcherServlet::handle_request(
  self : DispatcherServlet,
  request : @Http.HttpRequest
) -> @Http.HttpResponse {
  // 1. 执行过滤器链（如果过滤器返回响应，则直接返回）
  match self.apply_filters(request) {
    Some(response) => response
    None => {
      // 2. 查找匹配的 Controller 或 RestController
      match self.find_handler(request) {
        Some(handler_info) => {
          // 3. 执行处理器
          match handler_info {
            ControllerHandler(handler) => {
              // Controller 处理器
              handler(request)
            }
            RestControllerHandler(handler) => {
              // RestController 处理器
              let json_response = handler(request)
              json_response.to_http_response()
            }
          }
        }
        None => {
          // 4. 未找到处理器
          @Http.HttpResponse::not_found(None)
        }
      }
    }
  }
}

/// 处理异常（供外部调用）
/// 
/// 参数：
/// - exception: 应用程序异常
/// - request: HTTP 请求
/// 
/// 返回值：
/// - HTTP 响应
pub fn DispatcherServlet::handle_exception(
  self : DispatcherServlet,
  exception : @Exception.ApplicationException,
  request : @Http.HttpRequest
) -> @Http.HttpResponse {
  match self.exception_handler {
    Some(handler) => {
      handler.handle_exception(exception, request)
    }
    None => {
      // 没有异常处理器，返回默认错误响应
      @Http.HttpResponse::internal_server_error(None)
    }
  }
}

/// 应用过滤器链
/// 
/// 按顺序执行所有匹配的过滤器
/// 如果过滤器返回响应，则直接返回；否则返回 None，由处理器生成响应
fn DispatcherServlet::apply_filters(
  self : DispatcherServlet,
  request : @Http.HttpRequest
) -> @Http.HttpResponse? {
  let request_path = request.get_path()
  let matched_filters : Array[@Filter.FilterRegistrationBean] = []
  
  // 1. 收集匹配的过滤器
  let mut i = 0
  while i < self.filters.length() {
    let filter_registration = self.filters[i]
    if filter_registration.matches_url(request_path) {
      matched_filters.push(filter_registration)
    }
    i = i + 1
  }
  
  // 2. 如果没有匹配的过滤器，返回 None
  if matched_filters.length() == 0 {
    None
  } else {
    // 3. 按顺序执行过滤器
    // 简化实现：每个过滤器都可以修改请求或响应
    // 如果过滤器返回响应，则停止执行
    let mut current_response : @Http.HttpResponse? = None
    let mut filter_index = 0
    
    while filter_index < matched_filters.length() {
      let filter_registration = matched_filters[filter_index]
      let filter_func = filter_registration.get_filter_func()
      
      // 创建过滤器链：下一个过滤器或处理器
      let next_handler = fn() -> @Http.HttpResponse {
        // 如果还有下一个过滤器，调用它；否则返回默认响应（由处理器生成）
        if filter_index + 1 < matched_filters.length() {
          // 调用下一个过滤器（简化实现）
          @Http.HttpResponse::internal_server_error(None)
        } else {
          // 过滤器链结束，返回 None（由处理器生成响应）
          @Http.HttpResponse::internal_server_error(None)
        }
      }
      
      // 执行过滤器函数
      let response = filter_func(request, current_response, next_handler)
      
      // 如果过滤器返回响应，检查是否应该继续
      // 简化实现：如果过滤器返回响应，则停止执行
      current_response = Some(response)
      
      filter_index = filter_index + 1
    }
    
    // 返回最后一个过滤器的响应（如果有）
    current_response
  }
}

/// 处理器信息（用于区分 Controller 和 RestController）
pub enum HandlerInfo {
  ControllerHandler(@Controller.ControllerHandler)
  RestControllerHandler(@Controller.RestControllerHandler)
}

/// 查找匹配的处理器
/// 
/// 参数：
/// - request: HTTP 请求
/// 
/// 返回值：
/// - Some(handler_info): 找到匹配的处理器
/// - None: 未找到匹配的处理器
fn DispatcherServlet::find_handler(
  self : DispatcherServlet,
  request : @Http.HttpRequest
) -> HandlerInfo? {
  let request_path = request.get_path()
  let request_method = request.get_method()
  
  // 先查找 Controller
  let mut matched_handler : HandlerInfo? = None
  
  self.controllers.iter().each(fn(entry) {
    let (_name, controller) = entry
    let base_path = controller.get_base_path()
    
    // 检查路径是否匹配 Controller 的基础路径
    if request_path.has_prefix(base_path) {
      // 提取相对路径（去掉 base_path）
      let relative_path = try {
        if request_path.length() > base_path.length() {
          request_path[base_path.length():].to_string()
        } else {
          "/"
        }
      } catch {
        _ => "/"
      }
      
      // 查找匹配的方法
      match controller.find_handler(request_method, relative_path) {
        Some(handler) => {
          matched_handler = Some(ControllerHandler(handler))
        }
        None => ()
      }
    }
  })
  
  // 如果找到了 Controller，直接返回
  match matched_handler {
    Some(_) => matched_handler
    None => {
      // 查找 RestController
      self.rest_controllers.iter().each(fn(entry) {
        let (_name, rest_controller) = entry
        let base_path = rest_controller.get_base_path()
        
        // 检查路径是否匹配 RestController 的基础路径
        if request_path.has_prefix(base_path) {
          // 提取相对路径（去掉 base_path）
          let relative_path = try {
            if request_path.length() > base_path.length() {
              request_path[base_path.length():].to_string()
            } else {
              "/"
            }
          } catch {
            _ => "/"
          }
          
          // 查找匹配的方法
          match rest_controller.find_handler(request_method, relative_path) {
            Some(handler) => {
              matched_handler = Some(RestControllerHandler(handler))
            }
            None => ()
          }
        }
      })
      
      matched_handler
    }
  }
}

/// 按 order 排序过滤器
fn sort_filters_by_order(filters : Array[@Filter.FilterRegistrationBean]) -> Array[@Filter.FilterRegistrationBean] {
  // 简化实现：使用冒泡排序
  let sorted = filters
  let mut swapped = true
  
  while swapped {
    swapped = false
    let mut i = 0
    while i < sorted.length() - 1 {
      let current_order = sorted[i].get_order()
      let next_order = sorted[i + 1].get_order()
      
      if current_order > next_order {
        // 交换元素
        let temp = sorted[i]
        sorted[i] = sorted[i + 1]
        sorted[i + 1] = temp
        swapped = true
      }
      
      i = i + 1
    }
  }
  
  sorted
}

