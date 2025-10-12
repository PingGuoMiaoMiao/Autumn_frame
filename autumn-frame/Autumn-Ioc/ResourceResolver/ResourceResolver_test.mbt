/// 测试 ResourceResolver 的使用示例

test "ResourceResolver 扫描文件示例" {
  // 创建一个 resolver，扫描 "com.example.config" 包
  let resolver = ResourceResolver::new("com.example.config")
  
  // 示例 1: 收集所有 .json 配置文件的路径
  let json_files : @list.List[String] = resolver.scan(fn(res : Resource) -> String? {
    if res.name.has_suffix(".json") {
      Some(res.path)
    } else {
      None
    }
  })
  
  println("找到的 JSON 文件数量: \{json_files.length()}")
  
  // 示例 2: 收集所有资源对象
  let all_resources : @list.List[Resource] = resolver.scan(fn(res : Resource) -> Resource? {
    Some(res)
  })
  
  println("所有资源数量: \{all_resources.length()}")
  
  // 示例 3: 只收集 .mbt 源文件的名称
  let mbt_names : @list.List[String] = resolver.scan(fn(res : Resource) -> String? {
    if res.name.has_suffix(".mbt") {
      Some(res.name)
    } else {
      None
    }
  })
  
  println("找到的 .mbt 文件: \{mbt_names.length()}")
}

test "ResourceResolver 映射过滤示例" {
  let resolver = ResourceResolver::new("cmd.main")
  
  // 使用 mapper 函数过滤和转换
  // 假设我们只想要 main.mbt 文件
  let main_files = resolver.scan(fn(res : Resource) -> Resource? {
    if res.name == "main.mbt" {
      Some(res)
    } else {
      None
    }
  })
  
  // 打印找到的文件
  let _ = main_files.map(fn(resource) {
    println("找到文件: path=\{resource.path}, name=\{resource.name}")
  })
}
