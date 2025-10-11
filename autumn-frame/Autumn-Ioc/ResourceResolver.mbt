/// ResourceResolver: 在给定 basePackage 下扫描资源（目录或 jar/zip）。
///
/// API:
/// - pub fn ResourceResolver::new(base_package : String) -> ResourceResolver
/// - pub fn [T] ResourceResolver::scan(self, mapper : (Resource) -> T?) -> List[T]
/// - pub fn ResourceResolver::with_debug(self, debug : Bool) -> ResourceResolver
/// - pub fn [T] ResourceResolver::scan_paths(self, paths : @list.List[String], mapper : (Resource) -> T?) -> List[T]
///
/// 实现说明：使用 `.mooncakes/moonbitlang/x/fs` 提供的 API（@fs.path_exists / @fs.read_dir / @fs.is_dir / @fs.is_file）。

pub struct ResourceResolver {
  base_package : String
  debug : Bool  // 是否启用调试日志
}

pub fn ResourceResolver::new(base_package : String) -> ResourceResolver {
  { base_package, debug: false }
}

/// 启用调试日志
pub fn ResourceResolver::with_debug(self : ResourceResolver, debug : Bool) -> ResourceResolver {
  { ..self, debug }
}

/// 内部日志函数
fn log_debug(resolver : ResourceResolver, message : String) -> Unit {
  if resolver.debug {
    println("[DEBUG] " + message)
  }
}

// scan 返回 @list.List[T]，mapper 返回 T? 表示是否收集（Some 则收集，None 则跳过）
pub fn [T] ResourceResolver::scan(self : ResourceResolver, mapper : (Resource) -> T?) -> @list.List[T] {
  let base_package_path = self.base_package.replace(old=".", new="/")
  log_debug(self, "Scanning base package: " + self.base_package + " (path: " + base_package_path + ")")
  
  let mut collector : @list.List[T] = @list.empty()

  // 从当前工作目录下的相对路径开始（"./<base_package_path>"）
  let candidate = "./" + base_package_path
  log_debug(self, "Checking candidate path: " + candidate)
  
  if @fs.path_exists(candidate) {
    try {
      if @fs.is_dir(candidate) {
        log_debug(self, "Found directory, starting recursive scan")
        collector = scan_dir(candidate, candidate, collector, mapper, self.debug)
      }
    } catch {
      _ => log_debug(self, "Error scanning directory: " + candidate)
    }
  } else {
    log_debug(self, "Path does not exist: " + candidate)
  }

  // 不自动扫描 jar/zip（可以后续按需添加 zip 支持）

  let result = collector.rev()
  log_debug(self, "Scan completed, found " + result.length().to_string() + " resources")
  return result
}

/// 扫描多个路径（替代 Java 的 ClassLoader.getResources()）
/// 
/// 用法示例：扫描多个目录来查找资源
pub fn [T] ResourceResolver::scan_paths(
  self : ResourceResolver,
  paths : @list.List[String],
  mapper : (Resource) -> T?
) -> @list.List[T] {
  log_debug(self, "Scanning multiple paths for package: " + self.base_package)
  
  let mut collector : @list.List[T] = @list.empty()
  let base_package_path = self.base_package.replace(old=".", new="/")
  
  // 遍历所有路径
  let _ = paths.map(fn(base_path) {
    let full_path = if base_package_path.length() > 0 {
      join_path_internal(base_path, base_package_path)
    } else {
      base_path
    }
    
    log_debug(self, "Checking path: " + full_path)
    
    if @fs.path_exists(full_path) {
      try {
        if @fs.is_dir(full_path) {
          log_debug(self, "Scanning directory: " + full_path)
          collector = scan_dir(full_path, full_path, collector, mapper, self.debug)
        }
      } catch {
        _ => log_debug(self, "Error scanning: " + full_path)
      }
    } else {
      log_debug(self, "Path not found: " + full_path)
    }
  })
  
  let result = collector.rev()
  log_debug(self, "Multi-path scan completed, found " + result.length().to_string() + " resources")
  return result
}

// 递归扫描目录并把 mapper 返回的 Some(v) 前插进 collector
fn [T] scan_dir(
  dir : String, 
  root : String, 
  collector : @list.List[T], 
  mapper : (Resource) -> T?,
  debug : Bool
) -> @list.List[T] {
  let mut acc = collector
  let entries = try {
    @fs.read_dir(dir)
  } catch {
    _ => []
  }
  
  if debug {
    println("[DEBUG] Scanning directory: " + dir + " (found " + entries.length().to_string() + " entries)")
  }
  
  for name in entries {
    // 使用 PathUtils 的功能
    let full = join_path_internal(dir, name)
    
    try {
      if @fs.is_dir(full) {
        acc = scan_dir(full, root, acc, mapper, debug)
      } else if @fs.is_file(full) {
        // 计算相对路径
        let rel = if full.has_prefix(root) {
          let sub = full[root.length():]
          if sub.has_prefix("/") { 
            remove_leading_slash_internal(sub.to_string())
          } else { 
            sub.to_string()
          }
        } else {
          name
        }
        
        let res = Resource::new("file:" + full, rel)
        
        if debug {
          println("[DEBUG] Found resource: path=" + res.path + ", name=" + res.name)
        }
        
        match mapper(res) {
          Some(v) => {
            acc = @list.cons(v, acc)
            if debug {
              println("[DEBUG] Resource collected")
            }
          }
          None => {
            if debug {
              println("[DEBUG] Resource skipped by mapper")
            }
          }
        }
      }
    } catch {
      _ => {
        if debug {
          println("[DEBUG] Error processing: " + full)
        }
      }
    }
  }
  return acc
}

// 内部辅助函数：移除前导斜杠
fn remove_leading_slash_internal(s : String) -> String {
  if s.has_prefix("/") || s.has_prefix("\\") {
    try {
      s[1:].to_string()
    } catch {
      _ => s
    }
  } else {
    s
  }
}

// 内部辅助函数：连接路径
fn join_path_internal(base : String, name : String) -> String {
  let sep = if base.has_suffix("/") { "" } else { "/" }
  base + sep + name
}

