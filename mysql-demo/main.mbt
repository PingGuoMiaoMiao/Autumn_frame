/// MySQL 数据库连接演示
/// 
/// 演示如何使用 FFI 连接真实的 MySQL 数据库
/// 
/// 注意：
/// - 仅在 native 后端可用（C 后端）
/// - 需要系统安装 MySQL C 客户端库（-lmysqlclient）
/// - 需要编译时指定 --target native

fn main {
  println("=".repeat(60))
  println("🌟 Autumn Frame - MySQL 数据库连接演示")
  println("=".repeat(60))
  println("")
  
  println("📝 注意：MySQL FFI 功能仅在 native 后端可用")
  println("   使用命令：moon build --target native")
  println("   或：moon run --target native mysql-demo")
  println("")
  
  // ========== 第一部分：创建 MySQL 数据源 ==========
  println("📦 第一步：创建 MySQL 数据源")
  println("─".repeat(60))
  
  // 创建 MySQL 数据源配置
  // 连接 information_schema 数据库
  let config = @JdbcTemplate.MySQLDataSourceConfig::new(
    "localhost",      // host
    3306,            // port
    "root",          // user
    "123456",        // password
    "information_schema" // database
  )
  let data_source = @JdbcTemplate.MySQLDataSource::new(config)
  println("✓ MySQL 数据源创建成功")
  println("")
  
  // ========== 第二部分：连接到数据库 ==========
  println("📝 第二步：连接到数据库")
  println("─".repeat(60))
  let connected_source = data_source.connect()
  println("")
  
  // ========== 第三部分：查询 TABLES 表信息 ==========
  println("📝 第三步：查询 information_schema.TABLES")
  println("─".repeat(60))
  
  // 查询 TABLES 表的前10条记录
  let row_mapper : @JdbcTemplate.RowMapper = fn(row : @JdbcTemplate.Row) {
    let mut result = ""
    let mut first = true
    row.iter().each(fn(entry : (String, String)) {
      let (key, value) = entry
      if first {
        result = result + key + "=" + value
        first = false
      } else {
        result = result + ", " + key + "=" + value
      }
    })
    result
  }
  
  // 查询 TABLES 表的前10条记录
  match connected_source.query("SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE, ENGINE FROM TABLES LIMIT 10", row_mapper) {
    Some(results) => {
      println("✓ 查询成功，找到 \{results.length()} 条记录：")
      let mut i = 0
      while i < results.length() {
        println("  - \{results[i]}")
        i = i + 1
      }
    }
    None => println("ℹ️  未找到记录或查询失败")
  }
  println("")
  
  // ========== 第四部分：查询 USERS 表信息 ==========
  println("📝 第四步：查询 information_schema.USERS")
  println("─".repeat(60))
  
  // 查询 users 表的所有记录（根据 MariaDB 输出，表名是 users，小写）
  match connected_source.query("SELECT * FROM users", row_mapper) {
    Some(results) => {
      println("✓ 查询成功，找到 \{results.length()} 条记录：")
      let mut i = 0
      while i < results.length() {
        println("  - \{results[i]}")
        i = i + 1
      }
    }
    None => println("ℹ️  未找到记录或查询失败（可能 USERS 表不存在）")
  }
  println("")
  
  // ========== 第五部分：查询 SCHEMATA 表（所有数据库） ==========
  println("📝 第五步：查询 information_schema.SCHEMATA（所有数据库）")
  println("─".repeat(60))
  
  match connected_source.query("SELECT SCHEMA_NAME, DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME FROM SCHEMATA LIMIT 10", row_mapper) {
    Some(results) => {
      println("✓ 查询成功，找到 \{results.length()} 个数据库：")
      let mut i = 0
      while i < results.length() {
        println("  - \{results[i]}")
        i = i + 1
      }
    }
    None => println("ℹ️  未找到记录或查询失败")
  }
  println("")
  
  // ========== 第六部分：查询 ENGINES 表（存储引擎） ==========
  println("📝 第六步：查询 information_schema.ENGINES（支持的存储引擎）")
  println("─".repeat(60))
  
  match connected_source.query("SELECT ENGINE, SUPPORT, COMMENT FROM ENGINES LIMIT 10", row_mapper) {
    Some(results) => {
      println("✓ 查询成功，找到 \{results.length()} 个存储引擎：")
      let mut i = 0
      while i < results.length() {
        println("  - \{results[i]}")
        i = i + 1
      }
    }
    None => println("ℹ️  未找到记录或查询失败")
  }
  println("")
  
  // ========== 第七部分：查询 COLUMNS 表（列信息） ==========
  println("📝 第七步：查询 information_schema.COLUMNS（表列信息）")
  println("─".repeat(60))
  
  match connected_source.query("SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE FROM COLUMNS WHERE TABLE_SCHEMA = 'information_schema' AND TABLE_NAME = 'TABLES' LIMIT 10", row_mapper) {
    Some(results) => {
      println("✓ 查询成功，找到 \{results.length()} 个列：")
      let mut i = 0
      while i < results.length() {
        println("  - \{results[i]}")
        i = i + 1
      }
    }
    None => println("ℹ️  未找到记录或查询失败")
  }
  println("")
  
  // ========== 第八部分：查询 PLUGINS 表（插件信息） ==========
  println("📝 第八步：查询 information_schema.PLUGINS（插件信息）")
  println("─".repeat(60))
  
  match connected_source.query("SELECT PLUGIN_NAME, PLUGIN_STATUS, PLUGIN_TYPE FROM PLUGINS LIMIT 10", row_mapper) {
    Some(results) => {
      println("✓ 查询成功，找到 \{results.length()} 个插件：")
      let mut i = 0
      while i < results.length() {
        println("  - \{results[i]}")
        i = i + 1
      }
    }
    None => println("ℹ️  未找到记录或查询失败")
  }
  println("")
  
  // ========== 第九部分：创建测试数据库和表 ==========
  println("📝 第九步：创建测试数据库和表")
  println("─".repeat(60))
  
  // 创建测试数据库（如果不存在）
  match connected_source.execute("CREATE DATABASE IF NOT EXISTS test_db") {
    Some(_) => println("✓ 数据库创建成功（或已存在）")
    None => println("ℹ️  数据库创建失败或已存在")
  }
  println("")
  
  // 切换到测试数据库（需要重新连接）
  let test_config = @JdbcTemplate.MySQLDataSourceConfig::new(
    "localhost",
    3306,
    "root",
    "123456",
    "test_db"
  )
  let test_data_source = @JdbcTemplate.MySQLDataSource::new(test_config)
  let test_connected = test_data_source.connect()
  println("✓ 已切换到 test_db 数据库")
  println("")
  
  // 创建测试表
  match test_connected.execute("CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), email VARCHAR(100), age INT)") {
    Some(_) => println("✓ 表创建成功（或已存在）")
    None => println("❌ 表创建失败")
  }
  println("")
  
  // ========== 第十部分：增删改查操作 ==========
  println("📝 第十步：增删改查操作")
  println("─".repeat(60))
  
  // 插入数据
  println("🔹 插入数据：")
  match test_connected.execute("INSERT INTO users (name, email, age) VALUES ('张三', 'zhangsan@example.com', 25)") {
    Some(_) => println("  ✓ 插入成功")
    None => println("  ❌ 插入失败")
  }
  
  match test_connected.execute("INSERT INTO users (name, email, age) VALUES ('李四', 'lisi@example.com', 30)") {
    Some(_) => println("  ✓ 插入成功")
    None => println("  ❌ 插入失败")
  }
  
  match test_connected.execute("INSERT INTO users (name, email, age) VALUES ('王五', 'wangwu@example.com', 28)") {
    Some(_) => println("  ✓ 插入成功")
    None => println("  ❌ 插入失败")
  }
  println("")
  
  // 查询数据
  println("🔹 查询所有数据：")
  match test_connected.query("SELECT id, name, email, age FROM users", row_mapper) {
    Some(results) => {
      println("  ✓ 查询成功，找到 \{results.length()} 条记录：")
      let mut i = 0
      while i < results.length() {
        println("    - \{results[i]}")
        i = i + 1
      }
    }
    None => println("  ℹ️  未找到记录")
  }
  println("")
  
  // 更新数据
  println("🔹 更新数据（将张三的年龄改为 26）：")
  match test_connected.execute("UPDATE users SET age = 26 WHERE name = '张三'") {
    Some(_) => println("  ✓ 更新成功")
    None => println("  ❌ 更新失败")
  }
  
  // 查询更新后的数据
  match test_connected.query("SELECT id, name, email, age FROM users WHERE name = '张三'", row_mapper) {
    Some(results) => {
      println("  ✓ 查询更新后的数据：")
      let mut i = 0
      while i < results.length() {
        println("    - \{results[i]}")
        i = i + 1
      }
    }
    None => println("  ℹ️  未找到记录")
  }
  println("")
  
  // 删除数据
  println("🔹 删除数据（删除王五的记录）：")
  match test_connected.execute("DELETE FROM users WHERE name = '王五'") {
    Some(_) => println("  ✓ 删除成功")
    None => println("  ❌ 删除失败")
  }
  
  // 查询删除后的数据
  match test_connected.query("SELECT id, name, email, age FROM users", row_mapper) {
    Some(results) => {
      println("  ✓ 查询删除后的数据，剩余 \{results.length()} 条记录：")
      let mut i = 0
      while i < results.length() {
        println("    - \{results[i]}")
        i = i + 1
      }
    }
    None => println("  ℹ️  未找到记录")
  }
  println("")
  
  // 断开测试数据库连接
  let _ = test_connected.disconnect()
  
  // ========== 第十一部分：断开连接 ==========
  println("📝 第十一步：断开连接")
  println("─".repeat(60))
  let _ = connected_source.disconnect()
  println("✓ 断开连接成功")
  println("")
  
  // ========== 总结 ==========
  println("=".repeat(60))
  println("📊 总结")
  println("=".repeat(60))
  println("✅ 已完成的功能：")
  println("  1. ✓ DatabaseFFI - MySQL FFI 外部函数声明")
  println("  2. ✓ MySQLDataSource - MySQL 数据源实现")
  println("  3. ✓ C 胶水函数 - mysql_wrapper.c")
  println("  4. ✓ 数据库连接 - connect/disconnect")
  println("  5. ✓ SQL 执行 - execute/query")
  println("")
  println("🎉 MySQL 数据库连接功能演示完成！")
  println("")
  println("⚠️  注意：")
  println("  - 此功能仅在 native 后端可用")
  println("  - wasm-gc 后端不支持 extern \"C\" fn")
  println("  - 需要系统安装 MySQL C 客户端库（-lmysqlclient）")
  println("  - 请根据实际情况修改连接参数（host, port, user, password, database）")
}

