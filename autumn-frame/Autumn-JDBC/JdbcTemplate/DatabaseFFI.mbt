/// DatabaseFFI - 数据库 FFI 接口定义
/// 
/// 通过 FFI（Foreign Function Interface）调用 C 数据库驱动
/// 
/// 支持的数据库：
/// 1. SQLite（推荐，最简单）
/// 2. MySQL（需要 MySQL C 客户端库）
/// 3. PostgreSQL（需要 libpq）
/// 
/// 使用方式：
/// 1. 在 Moonbit 中声明 FFI 函数
/// 2. 在 C 代码中实现这些函数
/// 3. 编译时将 C 代码链接到 Moonbit 程序
/// 
/// 注意：
/// - FFI 函数需要使用 `extern "C"` 声明
/// - 函数名需要匹配 C 实现的函数名
/// - 字符串参数需要转换为 C 字符串格式

// ========== SQLite FFI 接口 ==========

/// SQLite 数据库连接句柄
/// 注意：实际类型是 Int，表示连接句柄
pub type SqliteHandle = Int

/// 打开 SQLite 数据库
/// 
/// 参数：
/// - filename: 数据库文件路径
/// 
/// 返回值：
/// - >= 0: 成功，返回连接句柄
/// - < 0: 失败
#borrow(filename)
pub extern "C" fn sqlite3_open_ffi(
  filename : String
) -> Int = "autumn_sqlite3_open"

/// 执行 SQL 语句（不返回结果）
/// 
/// 参数：
/// - handle: 数据库连接句柄
/// - sql: SQL 语句
/// 
/// 返回值：
/// - 0: 成功
/// - 非0: 错误代码
#borrow(sql)
pub extern "C" fn sqlite3_exec_ffi(
  handle : SqliteHandle,
  sql : String
) -> Int = "autumn_sqlite3_exec"

/// 执行带参数的 SQL 语句（不返回结果）
/// 
/// 参数：
/// - handle: 数据库连接句柄
/// - sql: SQL 语句（使用 ? 作为占位符）
/// - params: 参数数组
/// 
/// 返回值：
/// - 0: 成功
/// - 非0: 错误代码
#borrow(sql, params)
pub extern "C" fn sqlite3_exec_prepared_ffi(
  handle : SqliteHandle,
  sql : String,
  params : Array[String]
) -> Int = "autumn_sqlite3_exec_prepared"

/// 查询数据（返回 FixedArray[String]）
/// 
/// 参数：
/// - handle: 数据库连接句柄
/// - sql: SQL 查询语句
/// - params: 参数数组
/// 
/// 返回值：
/// - 查询结果（FixedArray[String]），每行是一个字符串，格式：column1=value1\tcolumn2=value2\t...
/// - 空数组表示查询失败或无结果
#borrow(sql, params)
pub extern "C" fn sqlite3_query_ffi(
  handle : SqliteHandle,
  sql : String,
  params : Array[String]
) -> FixedArray[String] = "autumn_sqlite3_query"

/// 关闭数据库连接
pub extern "C" fn sqlite3_close_ffi(
  handle : SqliteHandle
) -> Int = "autumn_sqlite3_close"

/// 获取最后的错误信息
pub extern "C" fn sqlite3_errmsg_ffi(
  handle : SqliteHandle
) -> String = "autumn_sqlite3_errmsg"

// ========== MySQL FFI 接口 ==========

/// MySQL 数据库连接句柄
pub type MysqlHandle = Int

/// 连接到 MySQL 数据库
/// 
/// 参数：
/// - host: 主机地址
/// - port: 端口号
/// - user: 用户名
/// - password: 密码
/// - database: 数据库名
/// 
/// 返回值：
/// - Some(handle): 成功，返回连接句柄
/// - None: 失败（返回 -1）
#borrow(host, user, password, database)
pub extern "C" fn mysql_connect_ffi(
  host : String,
  port : Int,
  user : String,
  password : String,
  database : String
) -> MysqlHandle = "autumn_mysql_connect"

/// 执行 SQL 语句（不返回结果）
#borrow(sql)
pub extern "C" fn mysql_execute_ffi(
  handle : MysqlHandle,
  sql : String
) -> Int = "autumn_mysql_execute"

/// 查询数据（返回 FixedArray[String]）
/// 注意：根据 MoonBit FFI 官方文档，FixedArray[T] 在 C 中映射为 T*
///      而 Array[T] 的映射方式在文档中未明确提及，可能不支持直接返回
///      因此使用 FixedArray[String] 作为返回类型，然后在 MoonBit 侧转换为 Array
#borrow(sql, params)
pub extern "C" fn mysql_query_ffi(
  handle : MysqlHandle,
  sql : String,
  params : Array[String]
) -> FixedArray[String] = "autumn_mysql_query"

/// 关闭数据库连接
pub extern "C" fn mysql_close_ffi(
  handle : MysqlHandle
) -> Int = "autumn_mysql_close"

/// 获取最后的错误信息
pub extern "C" fn mysql_errmsg_ffi(
  handle : MysqlHandle
) -> String = "autumn_mysql_errmsg"

// ========== PostgreSQL FFI 接口 ==========

/// PostgreSQL 数据库连接句柄
pub type PgHandle = Int

/// 连接到 PostgreSQL 数据库
#borrow(host, user, password, database)
pub extern "C" fn pg_connect_ffi(
  host : String,
  port : Int,
  user : String,
  password : String,
  database : String
) -> PgHandle = "autumn_pg_connect"

/// 执行 SQL 语句
#borrow(sql, params)
pub extern "C" fn pg_execute_ffi(
  handle : PgHandle,
  sql : String,
  params : Array[String]
) -> Int = "autumn_pg_execute"

/// 查询数据
#borrow(sql, params)
pub extern "C" fn pg_query_ffi(
  handle : PgHandle,
  sql : String,
  params : Array[String]
) -> Array[String] = "autumn_pg_query"

/// 关闭数据库连接
pub extern "C" fn pg_close_ffi(
  handle : PgHandle
) -> Int = "autumn_pg_close"

/// 获取最后的错误信息
pub extern "C" fn pg_errmsg_ffi(
  handle : PgHandle
) -> String = "autumn_pg_errmsg"

