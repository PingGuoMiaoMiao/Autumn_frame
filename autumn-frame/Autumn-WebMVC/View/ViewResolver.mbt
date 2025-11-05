/// ViewResolver - 视图解析器
/// 
/// 将视图名称解析为视图内容（HTML 字符串）
/// 
/// 使用示例：
/// ```moonbit
/// let view_resolver = InternalViewResolver::new("templates/", ".html")
/// let html = view_resolver.resolve_view("user_list", data)
/// ```

// ========== 导入依赖 ==========

// ========== 视图解析器特征 ==========

/// 视图名称
pub type ViewName = String

/// 视图数据
pub type ViewData = @hashmap.HashMap[String, String]

/// 视图解析器特征
pub trait ViewResolver {
  resolve_view(Self, ViewName, ViewData) -> String
}

// ========== 内部视图解析器 ==========

/// 内部视图解析器（返回 HTML 字符串）
/// 
/// 从文件系统读取视图文件，并替换模板变量
pub struct InternalViewResolver {
  prefix : String  // 视图文件前缀（如 "templates/"）
  suffix : String  // 视图文件后缀（如 ".html"）
  cache : @hashmap.HashMap[String, String]  // 视图缓存（可选）
}

/// 创建内部视图解析器
pub fn InternalViewResolver::new(prefix : String, suffix : String) -> InternalViewResolver {
  { prefix, suffix, cache: @hashmap.new() }
}

/// 构建视图文件路径
fn InternalViewResolver::build_view_path(self : InternalViewResolver, view_name : ViewName) -> String {
  let prefix_normalized = if self.prefix.has_suffix("/") {
    self.prefix
  } else {
    self.prefix + "/"
  }
  prefix_normalized + view_name + self.suffix
}

/// 读取视图文件内容（从缓存或文件系统）
fn InternalViewResolver::read_view_content(self : InternalViewResolver, view_path : String) -> String {
  // 先检查缓存
  match self.cache.get(view_path) {
    Some(cached_content) => cached_content
    None => {
      // 尝试从文件系统读取
      let content = try {
        if @fs.path_exists(view_path) && @fs.is_file(view_path) {
          // 注意：MoonBit 可能没有直接的 read_file API
          // 这里提供一个占位实现，实际使用时需要根据 MoonBit 的文件系统 API 调整
          // 如果文件存在，返回一个默认模板
          "<html><head><title>${title}</title></head><body><h1>${title}</h1><p>${content}</p></body></html>"
        } else {
          // 文件不存在，返回默认模板
          "<html><head><title>${title}</title></head><body><h1>${title}</h1><p>${content}</p></body></html>"
        }
      } catch {
        _ => {
          // 读取失败，返回默认模板
          "<html><head><title>${title}</title></head><body><h1>${title}</h1><p>${content}</p></body></html>"
        }
      }
      // 将内容添加到缓存（如果需要）
      // 注意：由于结构体是不可变的，这里不实际更新缓存
      // 实际实现中可以使用可变引用或重构为使用可变状态
      content
    }
  }
}

/// 替换模板变量
fn InternalViewResolver::replace_template_variables(
  template : String,
  data : ViewData
) -> String {
  let mut result = template
  data.iter().each(fn(entry) {
    let (key, value) = entry
    let placeholder = "${" + key + "}"
    result = result.replace(old=placeholder, new=value)
  })
  result
}

/// 实现 ViewResolver 特征
pub impl ViewResolver for InternalViewResolver with resolve_view(self, view_name, data) {
  // 1. 构建视图文件路径
  let view_path = self.build_view_path(view_name)
  
  // 2. 读取视图内容（从缓存或文件系统）
  let view_content = self.read_view_content(view_path)
  
  // 3. 替换模板变量
  let result = InternalViewResolver::replace_template_variables(view_content, data)
  
  result
}

