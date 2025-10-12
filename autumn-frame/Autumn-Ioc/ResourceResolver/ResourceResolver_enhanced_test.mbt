/// 增强版 ResourceResolver 测试示例
/// 展示新增的调试日志和完整功能

// 辅助数据结构：文件信息
priv struct FileInfo {
  name : String
  is_test : Bool
}

test "ResourceResolver 带调试日志" {
  println("\n=== 测试 1: 带调试日志的扫描 ===")
  
  // 创建带调试日志的 resolver
  let resolver = ResourceResolver::new("autumn-frame.Autumn-Ioc")
    .with_debug(true)
  
  // 扫描所有 .mbt 文件
  let mbt_files = resolver.scan(fn(res : Resource) -> String? {
    if res.name.has_suffix(".mbt") {
      Some(res.name)
    } else {
      None
    }
  })
  
  println("\n找到 " + mbt_files.length().to_string() + " 个 .mbt 文件")
}

test "ResourceResolver 无调试日志（默认）" {
  println("\n=== 测试 2: 无调试日志的扫描 ===")
  
  // 默认不启用调试日志
  let resolver = ResourceResolver::new("autumn-frame.Autumn-Ioc")
  
  let all_resources = resolver.scan(fn(res : Resource) -> Resource? {
    Some(res)
  })
  
  println("找到 " + all_resources.length().to_string() + " 个资源")
}

test "ResourceResolver 复杂过滤" {
  println("\n=== 测试 3: 复杂过滤逻辑 ===")
  
  let resolver = ResourceResolver::new("autumn-frame.Autumn-Ioc")
    .with_debug(false)
  
  // 收集文件信息
  let file_infos : @list.List[FileInfo] = resolver.scan(fn(res : Resource) -> FileInfo? {
    if res.name.has_suffix(".mbt") {
      let is_test = res.name.has_suffix("_test.mbt")
      Some({ name: res.name, is_test })
    } else {
      None
    }
  })
  
  println("找到 " + file_infos.length().to_string() + " 个 .mbt 文件")
  
  // 显示部分结果
  let mut count = 0
  let _ = file_infos.map(fn(info) {
    if count < 5 {
      let tag = if info.is_test { "[测试]" } else { "[源码]" }
      println("  " + tag + " " + info.name)
      count = count + 1
    }
  })
}

test "ResourceResolver 文档文件扫描" {
  println("\n=== 测试 4: 扫描文档文件 ===")
  
  let resolver = ResourceResolver::new("autumn-frame.Autumn-Ioc")
  
  // 扫描所有 .md 文档
  let md_files = resolver.scan(fn(res : Resource) -> String? {
    if res.name.has_suffix(".md") {
      Some(res.name)
    } else {
      None
    }
  })
  
  println("找到 " + md_files.length().to_string() + " 个文档文件:")
  let _ = md_files.map(fn(name) {
    println("  - " + name)
  })
}

test "ResourceResolver 路径信息展示" {
  println("\n=== 测试 5: 完整路径信息 ===")
  
  let resolver = ResourceResolver::new("autumn-frame.Autumn-Ioc")
  
  // 收集完整的 Resource 对象
  let resources = resolver.scan(fn(res : Resource) -> Resource? {
    // 只收集前 5 个资源作为示例
    Some(res)
  })
  
  // 显示前几个资源的详细信息
  let mut count = 0
  let _ = resources.map(fn(res) {
    if count < 5 {
      println("资源 " + (count + 1).to_string() + ":")
      println("  完整路径: " + res.path)
      println("  相对名称: " + res.name)
      count = count + 1
    }
  })
  
  if resources.length() > 5 {
    println("... 还有 " + (resources.length() - 5).to_string() + " 个资源")
  }
}

test "ResourceResolver 链式调用风格" {
  println("\n=== 测试 6: 链式调用风格 ===")
  
  // 演示流式 API 风格
  let result = ResourceResolver::new("autumn-frame.Autumn-Ioc")
    .with_debug(false)
    .scan(fn(res) {
      if res.name.has_suffix(".mbt") && !res.name.has_suffix("_test.mbt") {
        Some(res.name)
      } else {
        None
      }
    })
  
  println("找到 " + result.length().to_string() + " 个非测试的 .mbt 文件")
}
