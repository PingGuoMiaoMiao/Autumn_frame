/// ResourceResolver: 在给定 basePackage 下扫描资源（目录或 jar/zip）。
///
/// API:
/// - pub fn ResourceResolver::new(base_package : String) -> ResourceResolver
/// - pub fn [T] ResourceResolver::scan(self, mapper : (Resource) -> T?) -> List[T]
///
/// 实现说明：使用 `.mooncakes/moonbitlang/x/fs` 提供的 API（@fs.path_exists / @fs.read_dir / @fs.is_dir / @fs.is_file）。

pub struct ResourceResolver {
  base_package : String
}

pub fn ResourceResolver::new(base_package : String) -> ResourceResolver {
  { base_package, }
}

// scan 返回 @list.List[T]，mapper 返回 T? 表示是否收集（Some 则收集，None 则跳过）
pub fn [T] ResourceResolver::scan(self : ResourceResolver, mapper : (Resource) -> T?) -> @list.List[T] {
  let base_package_path = self.base_package.replace(old=".", new="/")
  let mut collector : @list.List[T] = @list.empty()

  // 从当前工作目录下的相对路径开始（"./<base_package_path>"）
  let candidate = "./" + base_package_path
  if @fs.path_exists(candidate) {
    try {
      if @fs.is_dir(candidate) {
        collector = scan_dir(candidate, candidate, collector, mapper)
      }
    } catch {
      _ => () // 忽略错误继续
    }
  }

  // 不自动扫描 jar/zip（可以后续按需添加 zip 支持）

  return collector.rev()
}

// 递归扫描目录并把 mapper 返回的 Some(v) 前插进 collector
fn [T] scan_dir(dir : String, root : String, collector : @list.List[T], mapper : (Resource) -> T?) -> @list.List[T] {
  let mut acc = collector
  let entries = try {
    @fs.read_dir(dir)
  } catch {
    _ => []
  }
  for name in entries {
    let sep = if dir.has_suffix("/") { "" } else { "/" }
    let full = dir + sep + name
    try {
      if @fs.is_dir(full) {
        acc = scan_dir(full, root, acc, mapper)
      } else if @fs.is_file(full) {
        let rel = if full.has_prefix(root) {
          let sub = full[root.length():]
          if sub.has_prefix("/") { sub[1:].to_string() } else { sub.to_string() }
        } else {
          name
        }
        let res = Resource::new("file:" + full, rel)
        match mapper(res) {
          Some(v) => acc = @list.cons(v, acc)
          None => ()
        }
      }
    } catch {
      _ => () // 忽略单个文件错误继续扫描
    }
  }
  return acc
}

