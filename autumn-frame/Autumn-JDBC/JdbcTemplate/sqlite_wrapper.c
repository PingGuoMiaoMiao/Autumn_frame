// SQLite FFI 胶水函数
// 
// 此文件提供了 SQLite C API 与 MoonBit FFI 之间的适配层
//
// 编译：需要链接 -lsqlite3
// 使用：在 moon.pkg.json 的 "native-stub" 中配置

#include <sqlite3.h>
#include <string.h>
#include <stdlib.h>

// MoonBit 运行时头文件
// 注意：moonbit.h 位于 ~/.moon/include/，编译时需要 -I 参数指定
// 由于 MoonBit 构建系统会自动添加 -I$HOME/.moon/include，这里直接包含即可
#include <moonbit.h>

/// SQLite 打开数据库（适配 MoonBit FFI）
/// 
/// 参数：
/// - filename: 数据库文件路径（UTF-8 编码，MoonBit Bytes）
/// 
/// 返回：
/// - db: SQLite 数据库句柄（如果成功）
/// - NULL: 失败
sqlite3* sqlite3_open_wrapper(moonbit_bytes_t filename) {
    sqlite3* db = NULL;
    int rc;
    
    // 从 MoonBit Bytes 转换为 C 字符串
    // 注意：这里假设 Bytes 是 NULL 终止的，如果不是，需要额外处理
    const char* filename_str = (const char*)filename;
    
    // 调用 SQLite API
    rc = sqlite3_open(filename_str, &db);
    
    if (rc != SQLITE_OK) {
        // 打开失败，关闭数据库（如果有）
        if (db != NULL) {
            sqlite3_close(db);
        }
        return NULL;
    }
    
    return db;
}

/// SQLite 执行 SQL（简化版，不需要回调）
/// 
/// 参数：
/// - db: 数据库句柄
/// - sql: SQL 语句（UTF-8 编码，MoonBit Bytes）
/// 
/// 返回：
/// - SQLITE_OK: 成功
/// - 其他: 错误代码
int sqlite3_exec_simple(sqlite3* db, moonbit_bytes_t sql) {
    const char* sql_str = (const char*)sql;
    // sqlite3_exec 需要回调，这里使用简化版本
    // 实际使用中，可以提供一个简单的回调函数
    return sqlite3_exec(db, sql_str, NULL, NULL, NULL);
}

/// SQLite 关闭数据库
/// 
/// 参数：
/// - db: 数据库句柄
/// 
/// 返回：
/// - SQLITE_OK: 成功
/// - 其他: 错误代码
int sqlite3_close_wrapper(sqlite3* db) {
    return sqlite3_close(db);
}

/// SQLite 准备语句（返回语句句柄）
/// 
/// 参数：
/// - db: 数据库句柄
/// - sql: SQL 语句（UTF-8 编码，MoonBit Bytes）
/// 
/// 返回：
/// - stmt: 语句句柄（如果成功）
/// - NULL: 失败
sqlite3_stmt* sqlite3_prepare_wrapper(sqlite3* db, moonbit_bytes_t sql) {
    sqlite3_stmt* stmt = NULL;
    const char* sql_str = (const char*)sql;
    const char* tail = NULL;
    
    int rc = sqlite3_prepare_v2(db, sql_str, -1, &stmt, &tail);
    
    if (rc != SQLITE_OK) {
        return NULL;
    }
    
    return stmt;
}

/// SQLite 执行语句步骤
/// 
/// 参数：
/// - stmt: 语句句柄
/// 
/// 返回：
/// - SQLITE_ROW: 有结果行
/// - SQLITE_DONE: 完成
/// - 其他: 错误代码
int sqlite3_step_wrapper(sqlite3_stmt* stmt) {
    return sqlite3_step(stmt);
}

/// SQLite 获取列文本
/// 
/// 参数：
/// - stmt: 语句句柄
/// - index: 列索引（从0开始）
/// 
/// 返回：
/// - 列文本的指针（UTF-8编码）
const unsigned char* sqlite3_column_text_wrapper(sqlite3_stmt* stmt, int index) {
    return sqlite3_column_text(stmt, index);
}

/// SQLite 获取列字节数
/// 
/// 参数：
/// - stmt: 语句句柄
/// - index: 列索引（从0开始）
/// 
/// 返回：
/// - 列字节数
int sqlite3_column_bytes_wrapper(sqlite3_stmt* stmt, int index) {
    return sqlite3_column_bytes(stmt, index);
}

/// SQLite 完成语句
/// 
/// 参数：
/// - stmt: 语句句柄
/// 
/// 返回：
/// - SQLITE_OK: 成功
/// - 其他: 错误代码
int sqlite3_finalize_wrapper(sqlite3_stmt* stmt) {
    return sqlite3_finalize(stmt);
}

/// SQLite 获取更改行数
/// 
/// 参数：
/// - db: 数据库句柄
/// 
/// 返回：
/// - 更改的行数
int sqlite3_changes_wrapper(sqlite3* db) {
    return sqlite3_changes(db);
}
