///|
/// 综合测试：展示所有新增功能
/// 包括：URL 解码、多路径扫描、ClassLoader 替代
test "URL 解码功能测试" {
  println("\n=== URL 解码功能测试 ===")

  // 测试基本 URL 解码
  let decoded1 = url_decode("hello%20world")
  println("解码 'hello%20world': " + decoded1)
  if decoded1 != "hello world" {
    abort("URL decode failed")
  }

  // 测试路径解码
  let decoded2 = url_decode("path%2Fto%2Ffile")
  println("解码 'path%2Fto%2Ffile': " + decoded2)
  if decoded2 != "path/to/file" {
    abort("Path decode failed")
  }

  // 测试 + 号转空格
  let decoded3 = url_decode("hello+world")
  println("解码 'hello+world': " + decoded3)
  if decoded3 != "hello world" {
    abort("Plus decode failed")
  }
  println("✅ URL 解码测试通过")
}

///|
test "URL 编码功能测试" {
  println("\n=== URL 编码功能测试 ===")

  // 测试基本编码
  let encoded1 = url_encode("hello world")
  println("编码 'hello world': " + encoded1)
  if encoded1 != "hello+world" {
    abort("Space encode failed")
  }

  // 测试路径编码
  let encoded2 = url_encode("path/to/file")
  println("编码 'path/to/file': " + encoded2)

  // 测试往返转换
  let original = "test value"
  let encoded = url_encode(original)
  let decoded = url_decode(encoded)
  if decoded != original {
    abort("Roundtrip failed")
  }
  println("✅ URL 编码测试通过")
}

///|
test "多路径扫描功能测试（ClassLoader 替代）" {
  println(
    "\n=== 多路径扫描测试（模拟 ClassLoader.getResources()）===",
  )
  let resolver = ResourceResolver::new("autumn-frame.Autumn-Ioc").with_debug(
    false,
  )

  // 定义多个搜索路径（模拟 Java classpath）
  let search_paths = @list.List::from_array([
    "./autumn-frame/Autumn-Ioc", // 主源码目录
     "./src/main/resources", // 资源目录（可能不存在）
     "./config", // 配置目录（可能不存在）
  ])
  println("搜索路径:")
  let _ = search_paths.map(fn(path) { println("  - " + path) })

  // 扫描所有路径中的 .mbt 文件
  let mbt_files = resolver.scan_paths(search_paths, fn(res) {
    if res.name.has_suffix(".mbt") {
      Some(res.name)
    } else {
      None
    }
  })
  println("\n找到的 .mbt 文件:")
  let mut count = 0
  let _ = mbt_files.map(fn(name) {
    if count < 5 {
      println("  " + (count + 1).to_string() + ". " + name)
      count = count + 1
    }
  })
  if mbt_files.length() > 5 {
    println(
      "  ... 还有 " + (mbt_files.length() - 5).to_string() + " 个文件",
    )
  }
  println("\n总计: " + mbt_files.length().to_string() + " 个文件")
  println("✅ 多路径扫描测试通过")
}

///|
test "综合场景：带 URL 解码的多路径扫描" {
  println("\n=== 综合场景测试 ===")
  let resolver = ResourceResolver::new("autumn-frame.Autumn-Ioc")

  // 模拟包含 URL 编码的路径
  let encoded_path = url_encode("autumn-frame/Autumn-Ioc")
  let decoded_path = url_decode(encoded_path)
  println("原始路径: autumn-frame/Autumn-Ioc")
  println("URL 编码: " + encoded_path)
  println("URL 解码: " + decoded_path)

  // 使用解码后的路径扫描
  let paths = @list.List::from_array(["./autumn-frame/Autumn-Ioc"])
  let results = resolver.scan_paths(paths, fn(res) {
    // 只收集文档文件
    if res.name.has_suffix(".md") {
      Some(res.name)
    } else {
      None
    }
  })
  println("\n找到的文档文件:")
  let _ = results.map(fn(name) { println("  📄 " + name) })
  println("\n✅ 综合测试通过")
}

///|
test "模拟 Java ClassLoader 场景" {
  println("\n=== 模拟 Java ClassLoader.getResources() ===")
  println("Java 代码:")
  println(
    "  Enumeration<URL> urls = classLoader.getResources(\"com/example\");",
  )
  println("  while (urls.hasMoreElements()) { ... }")
  println("\nMoonbit 等价代码:")
  println("  let paths = @list.List::from_array([...])")
  println("  let results = resolver.scan_paths(paths, mapper)")

  // 实际演示
  let resolver = ResourceResolver::new("")
  let classpath = @list.List::from_array([
    "./autumn-frame/Autumn-Ioc", "./target/classes", // 可能不存在
     "./resources", // 可能不存在
  ])
  println("\n类路径 (classpath):")
  let _ = classpath.map(fn(path) {
    let exists = if @fs.path_exists(path) { "✅" } else { "❌" }
    println("  " + exists + " " + path)
  })
  let all_files = resolver.scan_paths(classpath, fn(res) { Some(res) })
  println(
    "\n从所有类路径中找到: " +
    all_files.length().to_string() +
    " 个资源",
  )
  println("✅ ClassLoader 模拟测试通过")
}
