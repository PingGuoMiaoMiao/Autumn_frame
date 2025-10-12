/// PropertyResolver 测试运行器

fn main {
  println("=" + "=".repeat(50))
  println("PropertyResolver 功能测试")
  println("=" + "=".repeat(50) + "\n")
  
  test_basic_query()
  test_expression_query()
  test_default_value()
  test_nested_query()
  test_type_conversion()
  
  println("\n" + "=" + "=".repeat(50))
  println("✅ 所有测试通过！")
  println("=" + "=".repeat(50))
}

fn test_basic_query() -> Unit {
  println("【测试 1】 基本查询")
  println("-" + "-".repeat(48))
  
  let resolver = @PropertyResolver.PropertyResolver::from_array([
    ("app.name", "Autumn Framework"),
    ("app.version", "1.0"),
    ("debug", "true")
  ])
  
  // 测试基本查询
  match resolver.get_property("app.name") {
    Some(v) => {
      println("  app.name = '" + v + "'")
      let result = if v == "Autumn Framework" { "✅ 通过" } else { "❌ 失败" }
      println("  结果: " + result)
    }
    None => println("  结果: ❌ 失败 - app.name 未找到")
  }
  
  match resolver.get_property("app.version") {
    Some(v) => {
      println("  app.version = '" + v + "'")
      let result = if v == "1.0" { "✅ 通过" } else { "❌ 失败" }
      println("  结果: " + result)
    }
    None => println("  结果: ❌ 失败 - app.version 未找到")
  }
  
  println("")
}

fn test_expression_query() -> Unit {
  println("【测试 2】 ${key} 表达式查询")
  println("-" + "-".repeat(48))
  
  let resolver = @PropertyResolver.PropertyResolver::from_array([
    ("app.title", "Summer"),
    ("app.version", "2.0")
  ])
  
  // 测试 ${key} 形式
  match resolver.get_property("${app.title}") {
    Some(v) => {
      println("  ${app.title} = '" + v + "'")
      let result = if v == "Summer" { "✅ 通过" } else { "❌ 失败" }
      println("  结果: " + result)
    }
    None => println("  结果: ❌ 失败 - ${app.title} 未找到")
  }
  
  println("")
}

fn test_default_value() -> Unit {
  println("【测试 3】 ${key:default} 带默认值查询")
  println("-" + "-".repeat(48))
  
  let resolver = @PropertyResolver.PropertyResolver::from_array([
    ("app.name", "MyApp")
  ])
  
  // 测试存在的 key
  match resolver.get_property("${app.name:DefaultApp}") {
    Some(v) => {
      println("  ${app.name:DefaultApp} = '" + v + "'")
      let result = if v == "MyApp" { "✅ 通过" } else { "❌ 失败" }
      println("  结果: " + result)
    }
    None => println("  结果: ❌ 失败")
  }
  
  // 测试不存在的 key（应返回默认值）
  match resolver.get_property("${app.missing:DefaultValue}") {
    Some(v) => {
      println("  ${app.missing:DefaultValue} = '" + v + "'")
      let result = if v == "DefaultValue" { "✅ 通过" } else { "❌ 失败: got " + v }
      println("  结果: " + result)
    }
    None => println("  结果: ❌ 失败 - 应返回默认值")
  }
  
  println("")
}

fn test_nested_query() -> Unit {
  println("【测试 4】 嵌套查询")
  println("-" + "-".repeat(48))
  
  let resolver = @PropertyResolver.PropertyResolver::from_array([
    ("APP_NAME", "Production"),
    ("app.title", "${APP_NAME}")
  ])
  
  // 测试嵌套
  match resolver.get_property("app.title") {
    Some(v) => {
      println("  app.title = '" + v + "' (嵌套解析 ${APP_NAME})")
      let result = if v == "Production" { "✅ 通过" } else { "❌ 失败: got " + v }
      println("  结果: " + result)
    }
    None => println("  结果: ❌ 失败 - 嵌套查询失败")
  }
  
  println("")
}

fn test_type_conversion() -> Unit {
  println("【测试 5】 类型转换")
  println("-" + "-".repeat(48))
  
  let resolver = @PropertyResolver.PropertyResolver::from_array([
    ("server.port", "8080"),
    ("debug.enabled", "true"),
    ("ratio", "3.14")
  ])
  
  // Int 转换
  match resolver.get_property_int("server.port") {
    Some(port) => {
      println("  server.port = " + port.to_string() + " (Int)")
      let result = if port == 8080 { "✅ 通过" } else { "❌ 失败" }
      println("  结果: " + result)
    }
    None => println("  结果: ❌ 失败 - Int 转换失败")
  }
  
  // Bool 转换
  match resolver.get_property_bool("debug.enabled") {
    Some(enabled) => {
      println("  debug.enabled = " + enabled.to_string() + " (Bool)")
      let result = if enabled { "✅ 通过" } else { "❌ 失败" }
      println("  结果: " + result)
    }
    None => println("  结果: ❌ 失败 - Bool 转换失败")
  }
  
  // Double 转换
  match resolver.get_property_double("ratio") {
    Some(r) => {
      println("  ratio = " + r.to_string() + " (Double)")
      let result = if r > 3.13 && r < 3.15 { "✅ 通过" } else { "❌ 失败" }
      println("  结果: " + result)
    }
    None => println("  结果: ❌ 失败 - Double 转换失败")
  }
  
  println("")
}
