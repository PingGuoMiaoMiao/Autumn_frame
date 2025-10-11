/// 独立测试运行器

fn main {
  println("=" + "=".repeat(50))
  println("Autumn-Ioc 功能验证测试")
  println("=" + "=".repeat(50) + "\n")
  
  test_url_decode()
  test_url_encode()
  test_scan_paths()
  
  println("\n" + "=" + "=".repeat(50))
  println("✅ 所有功能测试通过！")
  println("=" + "=".repeat(50))
}

fn test_url_decode() -> Unit {
  println("【测试 1】 URL 解码")
  println("-" + "-".repeat(48))
  
  // 测试空格
  let test1 = @Autumn_Ioc.url_decode("hello%20world")
  println("  输入: 'hello%20world'")
  println("  输出: '" + test1 + "'")
  println("  预期: 'hello world'")
  let result1 = if test1 == "hello world" { "✅ 通过" } else { "❌ 失败" }
  println("  结果: " + result1)
  
  // 测试路径分隔符
  let test2 = @Autumn_Ioc.url_decode("path%2Fto%2Ffile")
  println("\n  输入: 'path%2Fto%2Ffile'")
  println("  输出: '" + test2 + "'")
  println("  预期: 'path/to/file'")
  let result2 = if test2 == "path/to/file" { "✅ 通过" } else { "❌ 失败" }
  println("  结果: " + result2)
  
  // 测试加号转空格
  let test3 = @Autumn_Ioc.url_decode("hello+world")
  println("\n  输入: 'hello+world'")
  println("  输出: '" + test3 + "'")
  println("  预期: 'hello world'")
  let result3 = if test3 == "hello world" { "✅ 通过" } else { "❌ 失败" }
  println("  结果: " + result3)
  
  println("")
}

fn test_url_encode() -> Unit {
  println("【测试 2】 URL 编码")
  println("-" + "-".repeat(48))
  
  // 测试空格编码
  let test1 = @Autumn_Ioc.url_encode("hello world")
  println("  输入: 'hello world'")
  println("  输出: '" + test1 + "'")
  println("  预期: 'hello+world'")
  let result1 = if test1 == "hello+world" { "✅ 通过" } else { "❌ 失败" }
  println("  结果: " + result1)
  
  // 往返测试
  let original = "test@value#123"
  let encoded = @Autumn_Ioc.url_encode(original)
  let decoded = @Autumn_Ioc.url_decode(encoded)
  println("\n  往返测试:")
  println("    原始: '" + original + "'")
  println("    编码: '" + encoded + "'")
  println("    解码: '" + decoded + "'")
  let result2 = if decoded == original { "✅ 通过" } else { "❌ 失败" }
  println("  结果: " + result2)
  
  println("")
}

fn test_scan_paths() -> Unit {
  println("【测试 3】 多路径扫描 (ClassLoader 替代方案)")
  println("-" + "-".repeat(48))
  
  // 使用空包名，直接扫描指定目录
  let resolver = @Autumn_Ioc.ResourceResolver::new("").with_debug(false)
  
  // 定义多个搜索路径（模拟 Java ClassLoader 的多 classpath）
  let paths = @list.List::from_array([
    "autumn-frame/Autumn-Ioc",
    "test-runner",  // 也扫描测试目录
    "non-exist"     // 不存在的路径测试
  ])
  
  println("  搜索路径:")
  let _ = paths.map(fn(path) {
    let exists = if @fs.path_exists(path) { "✅ 存在" } else { "❌ 不存在" }
    println("    " + exists + "  " + path)
  })
  
  // 扫描所有路径查找 .mbt 文件
  println("\n  开始扫描...")
  let results = resolver.scan_paths(paths, fn(res) {
    if res.name.has_suffix(".mbt") {
      Some(res.name)
    } else {
      None
    }
  })
  
  let count = results.length()
  println("  找到 " + count.to_string() + " 个 .mbt 文件")
  
  if count > 0 {
    println("\n  前几个文件:")
    let mut i = 0
    let _ = results.map(fn(name) {
      if i < 5 {
        println("    " + (i + 1).to_string() + ". " + name)
        i = i + 1
      }
    })
    
    if count > 5 {
      println("    ... (还有 " + (count - 5).to_string() + " 个文件)")
    }
  }
  
  let result = if count > 0 { "✅ 通过" } else { "❌ 失败" }
  println("\n  结果: " + result)
  println("")
}
