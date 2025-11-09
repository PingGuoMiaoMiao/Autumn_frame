/// FilterRegistrationBean - 过滤器注册器
/// 
/// 用于注册和配置过滤器，以拦截和处理请求和响应
/// 
/// 使用示例：
/// ```moonbit
/// let filter_registration = FilterRegistrationBean::new("myFilter", my_filter)
///   .add_url_pattern("/*")
///   .set_order(1)
/// 
/// dispatcher.register_filter(filter_registration)
/// ```

// ========== 导入依赖 ==========

// ========== 过滤器接口 ==========

///|
/// 过滤器接口
/// 
/// 用于拦截和处理 HTTP 请求和响应
pub trait Filter {
  /// 执行过滤逻辑
  /// 
  /// 参数：
  /// - request: HTTP 请求
  /// - response: HTTP 响应（可选）
  /// - chain: 过滤器链（用于继续处理下一个过滤器或处理器）
  /// 
  /// 返回值：
  /// - HTTP 响应
  do_filter(Self, @Http.HttpRequest, @Http.HttpResponse?, FilterChain) -> @Http.HttpResponse
}

///|
/// 过滤器链
/// 
/// 用于继续执行下一个过滤器或处理器
pub type FilterChain = () -> @Http.HttpResponse

// ========== 过滤器注册器 ==========

///|
/// 过滤器函数类型
/// 
/// 用于执行过滤逻辑的函数类型
pub type FilterFunc = (@Http.HttpRequest, @Http.HttpResponse?, FilterChain) -> @Http.HttpResponse

///|
/// 过滤器注册器
/// 
/// 用于注册和配置过滤器
pub struct FilterRegistrationBean {
  name : String // 过滤器名称
  filter_func : FilterFunc // 过滤器函数
  url_patterns : Array[String] // URL 模式列表（如 ["/*", "/api/*"]）
  order : Int // 执行顺序（数字越小越先执行）
}

///|
/// 创建过滤器注册器
pub fn FilterRegistrationBean::new(
  name : String,
  filter_func : FilterFunc,
) -> FilterRegistrationBean {
  { name, filter_func, url_patterns: [], order: 0 }
}

///|
/// 添加 URL 模式
pub fn FilterRegistrationBean::add_url_pattern(
  self : FilterRegistrationBean,
  pattern : String,
) -> FilterRegistrationBean {
  let patterns_mut = self.url_patterns
  patterns_mut.push(pattern)
  { ..self, url_patterns: patterns_mut }
}

///|
/// 添加多个 URL 模式
pub fn FilterRegistrationBean::add_url_patterns(
  self : FilterRegistrationBean,
  patterns : Array[String],
) -> FilterRegistrationBean {
  let patterns_mut = self.url_patterns
  for pattern in patterns {
    patterns_mut.push(pattern)
  }
  { ..self, url_patterns: patterns_mut }
}

///|
/// 设置执行顺序
pub fn FilterRegistrationBean::set_order(
  self : FilterRegistrationBean,
  order : Int,
) -> FilterRegistrationBean {
  { ..self, order, }
}

///|
/// 获取过滤器名称
pub fn FilterRegistrationBean::get_name(
  self : FilterRegistrationBean,
) -> String {
  self.name
}

///|
/// 获取过滤器函数
pub fn FilterRegistrationBean::get_filter_func(
  self : FilterRegistrationBean,
) -> FilterFunc {
  self.filter_func
}

///|
/// 获取 URL 模式列表
pub fn FilterRegistrationBean::get_url_patterns(
  self : FilterRegistrationBean,
) -> Array[String] {
  self.url_patterns
}

///|
/// 获取执行顺序
pub fn FilterRegistrationBean::get_order(self : FilterRegistrationBean) -> Int {
  self.order
}

///|
/// 检查 URL 是否匹配过滤器模式
pub fn FilterRegistrationBean::matches_url(
  self : FilterRegistrationBean,
  url : String,
) -> Bool {
  // 如果 URL 模式列表为空，匹配所有 URL
  if self.url_patterns.length() == 0 {
    true
  } else {
    // 检查 URL 是否匹配任何一个模式
    let mut matched = false
    for pattern in self.url_patterns {
      if matches_pattern(url, pattern) {
        matched = true
        break
      }
    }
    matched
  }
}

///|
/// 检查 URL 是否匹配模式
/// 
/// 支持的模式：
/// - "/*" - 匹配所有路径
/// - "/api/*" - 匹配以 /api/ 开头的路径
/// - "/users/{id}" - 匹配 /users/ 后跟任意字符的路径
fn matches_pattern(url : String, pattern : String) -> Bool {
  // 精确匹配
  if url == pattern {
    true
  } else if pattern == "/*" {
    // 匹配所有路径
    true
  } else if pattern.has_suffix("/*") {
    // 前缀匹配（如 "/api/*"）
    let prefix = pattern[0:pattern.length() - 2].to_string() catch {
      _ => pattern
    }
    url.has_prefix(prefix)
  } else if pattern.contains("/*") {
    // 包含通配符的路径匹配
    let parts = Array::from_iter(pattern.split("/*"))
    if parts.length() >= 2 {
      let prefix = parts[0].to_string()
      url.has_prefix(prefix)
    } else {
      false
    }
  } else {
    // 其他情况，尝试简单的包含匹配
    url.has_prefix(pattern)
  }
}
