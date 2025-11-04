/// JDBC 和事务使用示例
/// 
/// 演示如何使用 JdbcTemplate 和声明式事务

fn main {
  println("=".repeat(60))
  println("🌟 Autumn Frame - JDBC 和事务使用示例")
  println("=".repeat(60))
  println("")
  
  // ========== 第一部分：创建 IoC 容器 ==========
  println("📦 第一步：创建 IoC 容器")
  println("─".repeat(60))
  let config : Array[(String, String)] = [
    ("app.name", "JDBC Demo"),
    ("db.url", "jdbc:mysql://localhost:3306/test"),
    ("db.username", "root"),
    ("db.password", "password")
  ]
  let ctx = @ApplicationContext.ApplicationContext::new(config, "com.example")
  println("✓ IoC 容器创建成功")
  println("")
  
  // ========== 第二部分：创建内存数据库和 JdbcTemplate ==========
  println("📝 第二步：创建内存数据库和 JdbcTemplate")
  println("─".repeat(60))
  
  // 创建内存数据库
  let database = @JdbcTemplate.MemoryDatabase::new()
  
  // 创建 JdbcTemplate（使用内存数据库）
  let jdbc_template = @JdbcTemplate.JdbcTemplate::new_with_memory_database(database)
  println("✓ JdbcTemplate 创建成功（使用内存数据库）")
  println("")
  
  // ========== 第三部分：使用 JdbcTemplate 执行操作 ==========
  println("📝 第三步：使用 JdbcTemplate 执行数据库操作")
  println("─".repeat(60))
  
  // 1. 插入操作
  println("1️⃣  插入操作")
  let insert_rows = jdbc_template.update("INSERT INTO users (name, email) VALUES (?, ?)", ["Alice", "alice@example.com"])
  println("   ✓ 插入成功，影响行数: \{insert_rows}")
  
  let insert_rows2 = jdbc_template.update("INSERT INTO users (name, email) VALUES (?, ?)", ["Bob", "bob@example.com"])
  println("   ✓ 插入成功，影响行数: \{insert_rows2}")
  println("")
  
  // 2. 查询操作
  println("2️⃣  查询操作")
  let row_mapper : @JdbcTemplate.RowMapper = fn(row : @JdbcTemplate.Row) {
    let mut result = ""
    row.iter().each(fn(entry : (String, String)) {
      let (key, value) = entry
      if result.length() > 0 {
        result = result + ", "
      }
      result = result + key + "=" + value
    })
    result
  }
  match jdbc_template.query("SELECT * FROM users WHERE id = ?", ["row_1"], row_mapper) {
    Some(result) => println("   ✓ 查询成功: \{result}")
    None => println("   ℹ️  未找到记录")
  }
  println("")
  
  // 3. 查询列表
  println("3️⃣  查询列表")
  let users = jdbc_template.query_for_list("SELECT * FROM users", [], row_mapper)
  println("   ✓ 查询成功，找到 \{users.length()} 条记录")
  users.iter().each(fn(user) {
    println("     - \{user}")
  })
  println("")
  
  // 4. 更新操作
  println("4️⃣  更新操作")
  let affected_rows = jdbc_template.update("UPDATE users SET name = ? WHERE id = ?", ["AliceUpdated", "row_1"])
  println("   ✓ 更新成功，影响行数: \{affected_rows}")
  
  // 再次查询验证更新
  match jdbc_template.query("SELECT * FROM users WHERE id = ?", ["row_1"], row_mapper) {
    Some(result) => println("   ✓ 更新后查询: \{result}")
    None => println("   ℹ️  未找到记录")
  }
  println("")
  
  // 5. 批量插入
  println("5️⃣  批量插入")
  let batch_params = [
    ["Charlie", "charlie@example.com"],
    ["David", "david@example.com"],
    ["Eve", "eve@example.com"]
  ]
  let batch_results = jdbc_template.batch_update("INSERT INTO users (name, email) VALUES (?, ?)", batch_params)
  println("   ✓ 批量插入完成，插入 \{batch_results.length()} 条记录")
  println("")
  
  // 6. 删除操作
  println("6️⃣  删除操作")
  let deleted_rows = jdbc_template.update("DELETE FROM users WHERE id = ?", ["row_1"])
  println("   ✓ 删除成功，影响行数: \{deleted_rows}")
  println("")
  
  // ========== 第四部分：创建事务管理器 ==========
  println("📝 第四步：创建事务管理器")
  println("─".repeat(60))
  let transaction_manager = @Transaction.TransactionManager::new()
  println("✓ 事务管理器创建成功")
  println("")
  
  // ========== 第五部分：创建 AOP 集成器 ==========
  println("📝 第五步：创建 AOP 集成器（用于声明式事务）")
  println("─".repeat(60))
  let aop = @AopIntegration.AopIntegration::new()
  println("✓ AOP 集成器创建成功")
  println("")
  
  // ========== 第六部分：注册 Bean ==========
  println("📝 第六步：注册 Bean")
  println("─".repeat(60))
  ctx.register_bean("userService", "com.example.UserService", 10, true)
  println("✓ 注册了 userService Bean")
  println("")
  
  // ========== 第七部分：配置声明式事务 ==========
  println("📝 第七步：配置声明式事务（@Transactional）")
  println("─".repeat(60))
  
  // 创建事务定义（使用默认配置）
  let transaction_def = @Transaction.TransactionDefinition::default()
  
  // 为 userService 的 saveUser 和 deleteUser 方法注册事务切面
  let transactional_methods = ["saveUser", "deleteUser"]
  @TransactionAspect.register_transaction_aspect(
    aop,
    transaction_manager,
    "userService",
    transactional_methods,
    transaction_def
  )
  println("")
  
  // ========== 第八部分：创建 Bean 并测试事务 ==========
  println("📝 第八步：创建 Bean 并测试事务")
  println("─".repeat(60))
  
  // 注册 Bean 创建函数
  ctx.register_bean_creator("userService", fn(_ctx) { "instance_userService_001" })
  
  // 创建 Bean
  ctx.create_all_beans_enhanced()
  println("")
  
  // ========== 总结 ==========
  println("=".repeat(60))
  println("📊 总结")
  println("=".repeat(60))
  println("✅ 已完成的功能：")
  println("  1. ✓ MemoryDatabase - 内存数据库（真实执行 SQL！）")
  println("  2. ✓ JdbcTemplate - JDBC 模板类（execute、query、update、batch_update）")
  println("  3. ✓ DataSource - 数据源接口和实现")
  println("  4. ✓ RowMapper - 行映射器")
  println("  5. ✓ TransactionManager - 事务管理器（开始、提交、回滚）")
  println("  6. ✓ TransactionDefinition - 事务定义（隔离级别、传播行为）")
  println("  7. ✓ 声明式事务 - 通过 AOP 实现 @Transactional")
  println("")
  println("🎉 内存数据库功能演示完成！SQL 真的可以执行了！")
}
