/// PathUtils: 路径处理工具函数
/// 
/// 提供与 Java ResourceResolver 类似的路径规范化功能

/// 移除路径开头的斜杠（/ 或 \）
pub fn remove_leading_slash(s : String) -> String {
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

/// 移除路径末尾的斜杠（/ 或 \）
pub fn remove_trailing_slash(s : String) -> String {
  let len = s.length()
  if len > 0 && (s.has_suffix("/") || s.has_suffix("\\")) {
    try {
      s[0:len - 1].to_string()
    } catch {
      _ => s
    }
  } else {
    s
  }
}

/// 规范化路径：移除首尾的斜杠
pub fn normalize_path(s : String) -> String {
  s |> remove_leading_slash |> remove_trailing_slash
}

/// 连接路径片段，自动处理分隔符
pub fn join_path(base : String, name : String) -> String {
  let base_normalized = remove_trailing_slash(base)
  let name_normalized = remove_leading_slash(name)
  if base_normalized.is_empty() {
    name_normalized
  } else if name_normalized.is_empty() {
    base_normalized
  } else {
    base_normalized + "/" + name_normalized
  }
}

test "remove_leading_slash" {
  if remove_leading_slash("/path/to/file") != "path/to/file" {
    abort("remove_leading_slash failed")
  }
  if remove_leading_slash("\\path\\to\\file") != "path\\to\\file" {
    abort("remove_leading_slash failed")
  }
  if remove_leading_slash("path/to/file") != "path/to/file" {
    abort("remove_leading_slash failed")
  }
}

test "remove_trailing_slash" {
  if remove_trailing_slash("/path/to/dir/") != "/path/to/dir" {
    abort("remove_trailing_slash failed")
  }
  if remove_trailing_slash("/path/to/dir\\") != "/path/to/dir" {
    abort("remove_trailing_slash failed")
  }
  if remove_trailing_slash("/path/to/dir") != "/path/to/dir" {
    abort("remove_trailing_slash failed")
  }
}

test "normalize_path" {
  if normalize_path("/path/to/dir/") != "path/to/dir" {
    abort("normalize_path failed")
  }
  if normalize_path("path/to/dir") != "path/to/dir" {
    abort("normalize_path failed")
  }
}

test "join_path" {
  if join_path("/base/", "/path") != "/base/path" {
    abort("join_path failed")
  }
  if join_path("/base", "path") != "/base/path" {
    abort("join_path failed")
  }
  if join_path("/base/", "path") != "/base/path" {
    abort("join_path failed")
  }
  if join_path("", "path") != "path" {
    abort("join_path failed")
  }
  if join_path("base", "") != "base" {
    abort("join_path failed")
  }
}
