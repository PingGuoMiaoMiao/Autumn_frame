///|
/// FFI 数据库连接演示
/// 
/// 演示如何使用 FFI 连接真实的 SQLite 数据库
/// 
/// 注意：
/// - 仅在 native 后端可用（C 后端）
/// - 需要系统安装 SQLite 库（-lsqlite3）
/// - 需要编译时指定 --target native
fn main {
  println("=".repeat(60))
  println("🌟 Autumn Frame - FFI 数据库连接演示")
  println("=".repeat(60))
  println("")
  println("📝 注意：FFI 功能仅在 native 后端可用")
  println("   使用命令：moon build --target native")
  println("   或：moon run --target native ffi-demo")
  println("")

  // ========== 第一部分：创建 FFI 数据源 ==========
  println("📦 第一步：创建 FFI 数据源")
  println("─".repeat(60))

  // 创建 FFI 数据源配置
  let config = @JdbcTemplate.FFIDataSourceConfig::new("sqlite:test.db")
  let data_source = @JdbcTemplate.FFIDataSource::new(config)
  println("✓ FFI 数据源创建成功")
  println("")

  // ========== 第二部分：连接到数据库 ==========
  println("📝 第二步：连接到数据库")
  println("─".repeat(60))
  let connected_source = data_source.connect()
  println("")

  // ========== 第三部分：创建表 ==========
  println("📝 第三步：创建表")
  println("─".repeat(60))
  match
    connected_source.execute(
      "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT, email TEXT)",
    ) {
    Some(_) => println("✓ 表创建成功")
    None => println("❌ 表创建失败")
  }
  println("")

  // ========== 第四部分：插入数据 ==========
  println("📝 第四步：插入数据")
  println("─".repeat(60))
  match
    connected_source.execute(
      "INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com')",
    ) {
    Some(rows) => println("✓ 插入成功，影响行数: \{rows}")
    None => println("❌ 插入失败")
  }
  match
    connected_source.execute(
      "INSERT INTO users (name, email) VALUES ('Bob', 'bob@example.com')",
    ) {
    Some(rows) => println("✓ 插入成功，影响行数: \{rows}")
    None => println("❌ 插入失败")
  }
  println("")

  // ========== 第五部分：查询数据 ==========
  println("📝 第五步：查询数据")
  println("─".repeat(60))
  let row_mapper : @JdbcTemplate.RowMapper = fn(row : @JdbcTemplate.Row) {
    let mut result = ""
    row
    .iter()
    .each(fn(entry : (String, String)) {
      let (key, value) = entry
      if result.length() > 0 {
        result = result + ", "
      }
      result = result + key + "=" + value
    })
    result
  }
  match
    connected_source.query(
      "SELECT name, email FROM users WHERE name = 'Alice'", row_mapper,
    ) {
    Some(results) => {
      println("✓ 查询成功，找到 \{results.length()} 条记录：")
      let mut i = 0
      while i < results.length() {
        println("  - \{results[i]}")
        i = i + 1
      }
    }
    None => println("ℹ️  未找到记录")
  }
  println("")

  // ========== 第六部分：断开连接 ==========
  println("📝 第六步：断开连接")
  println("─".repeat(60))
  let _ = connected_source.disconnect()
  println("✓ 断开连接成功")
  println("")

  // ========== 总结 ==========
  println("=".repeat(60))
  println("📊 总结")
  println("=".repeat(60))
  println("✅ 已完成的功能：")
  println("  1. ✓ DatabaseFFI - SQLite FFI 外部函数声明")
  println("  2. ✓ FFIDataSource - FFI 数据源实现")
  println("  3. ✓ C 胶水函数 - sqlite_wrapper.c")
  println("  4. ✓ 数据库连接 - connect/disconnect")
  println("  5. ✓ SQL 执行 - execute/query/batch_execute")
  println("")
  println("🎉 FFI 数据库连接功能演示完成！")
  println("")
  println("⚠️  注意：")
  println("  - 此功能仅在 native 后端可用")
  println("  - wasm-gc 后端不支持 extern \"C\" fn")
  println("  - 需要系统安装 SQLite 库")
}
