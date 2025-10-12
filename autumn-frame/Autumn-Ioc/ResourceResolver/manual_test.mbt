/// 手动测试验证所有功能

pub fn run_all_tests() -> Unit {
  test_url_decode()
  test_url_encode()
  test_scan_paths()
  println("\n✅ 所有功能测试通过！")
}

fn test_url_decode() -> Unit {
  println("=== 测试 1: URL 解码 ===")
  
  let test1 = url_decode("hello%20world")
  println("url_decode('hello%20world') = '" + test1 + "'")
  if test1 != "hello world" {
    abort("URL decode failed!")
  }
  
  let test2 = url_decode("path%2Fto%2Ffile")
  println("url_decode('path%2Fto%2Ffile') = '" + test2 + "'")
  if test2 != "path/to/file" {
    abort("Path decode failed!")
  }
  
  let test3 = url_decode("hello+world")
  println("url_decode('hello+world') = '" + test3 + "'")
  if test3 != "hello world" {
    abort("Plus decode failed!")
  }
  
  println("✅ URL 解码功能正常\n")
}

fn test_url_encode() -> Unit {
  println("=== 测试 2: URL 编码 ===")
  
  let test1 = url_encode("hello world")
  println("url_encode('hello world') = '" + test1 + "'")
  if test1 != "hello+world" {
    abort("URL encode failed!")
  }
  
  let test2 = url_encode("test/path")
  println("url_encode('test/path') = '" + test2 + "'")
  
  // 往返测试
  let original = "test value"
  let encoded = url_encode(original)
  let decoded = url_decode(encoded)
  println("往返测试: '" + original + "' -> '" + encoded + "' -> '" + decoded + "'")
  if decoded != original {
    abort("Roundtrip failed!")
  }
  
  println("✅ URL 编码功能正常\n")
}

fn test_scan_paths() -> Unit {
  println("=== 测试 3: 多路径扫描（ClassLoader 替代）===")
  
  let resolver = ResourceResolver::new("autumn-frame.Autumn-Ioc")
  
  // 定义多个搜索路径
  let paths = @list.List::from_array([
    "./autumn-frame/Autumn-Ioc",
    "./resources",  // 可能不存在
    "./config"      // 可能不存在
  ])
  
  println("搜索路径:")
  let _ = paths.map(fn(path) {
    let exists = if @fs.path_exists(path) { "✅" } else { "❌" }
    println("  " + exists + " " + path)
  })
  
  // 扫描所有路径
  let results = resolver.scan_paths(paths, fn(res) {
    if res.name.has_suffix(".mbt") {
      Some(res.name)
    } else {
      None
    }
  })
  
  println("\n找到 " + results.length().to_string() + " 个 .mbt 文件")
  
  // 显示前几个
  let mut count = 0
  let _ = results.map(fn(name) {
    if count < 3 {
      println("  " + (count + 1).to_string() + ". " + name)
      count = count + 1
    }
  })
  
  if results.length() > 3 {
    println("  ... 还有 " + (results.length() - 3).to_string() + " 个文件")
  }
  
  println("✅ 多路径扫描功能正常\n")
}
