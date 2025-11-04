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
#include <moonbit.h>

// 全局数据库句柄映射表（简化实现：使用数组）
#define MAX_HANDLES 100
static sqlite3* db_handles[MAX_HANDLES] = {NULL};

// 获取数据库句柄
static sqlite3* get_db(int handle) {
    if (handle >= 0 && handle < MAX_HANDLES) {
        return db_handles[handle];
    }
    return NULL;
}

// 存储数据库句柄并返回句柄 ID
static int store_db(sqlite3* db) {
    if (db == NULL) {
        return -1;
    }
    for (int i = 0; i < MAX_HANDLES; i++) {
        if (db_handles[i] == NULL) {
            db_handles[i] = db;
            return i;
        }
    }
    return -1; // 句柄表已满
}

// 移除数据库句柄
static void remove_db(int handle) {
    if (handle >= 0 && handle < MAX_HANDLES) {
        db_handles[handle] = NULL;
    }
}

// UTF-16 到 UTF-8 转换缓冲区（静态分配，避免内存泄漏）
static char utf8_buffer[4096];

// 从 MoonBit String (UTF-16) 获取 C 字符串 (UTF-8)
static const char* get_c_string(moonbit_string_t str) {
    if (str == NULL) {
        return "";
    }
    
    // MoonBit String 是 UTF-16 编码，需要转换为 UTF-8
    // 简化实现：对于 ASCII 字符（0x00-0x7F），UTF-16 的低字节就是 UTF-8
    // 注意：MoonBit String 可能使用不同的内部结构，需要检查实际布局
    
    int i = 0;
    int j = 0;
    
    // 遍历 UTF-16 字符串，直到遇到 NULL 终止符或缓冲区满
    // 注意：MoonBit String 可能不是以 NULL 终止的，需要检查长度
    while (j < sizeof(utf8_buffer) - 1) {
        uint16_t code_unit = str[i];
        
        // 检查是否是 NULL 终止符
        if (code_unit == 0) {
            break;
        }
        
        // ASCII 字符（0x00-0x7F）：直接使用低字节
        if (code_unit < 0x80) {
            utf8_buffer[j++] = (char)code_unit;
        } else if (code_unit < 0x800) {
            // 2 字节 UTF-8 字符（简化实现）
            utf8_buffer[j++] = (char)(0xC0 | (code_unit >> 6));
            if (j < sizeof(utf8_buffer) - 1) {
                utf8_buffer[j++] = (char)(0x80 | (code_unit & 0x3F));
            }
        } else {
            // 3 字节或更多（简化处理，使用替换字符）
            utf8_buffer[j++] = '?';
        }
        
        i++;
        
        // 防止无限循环（如果字符串没有 NULL 终止符）
        if (i > 4095) {
            break;
        }
    }
    
    utf8_buffer[j] = '\0'; // 确保 NULL 终止
    return utf8_buffer;
}

/// SQLite 打开数据库（适配 MoonBit FFI）
/// 
/// 参数：
/// - filename: 数据库文件路径（MoonBit String）
/// 
/// 返回：
/// - >= 0: 成功，返回连接句柄 ID
/// - < 0: 失败
int autumn_sqlite3_open(moonbit_string_t filename) {
    sqlite3* db = NULL;
    int rc;
    
    // 从 MoonBit String 转换为 C 字符串
    // 注意：实际实现需要 UTF-16 到 UTF-8 转换
    const char* filename_str = get_c_string(filename);
    
    // 调用 SQLite API
    rc = sqlite3_open(filename_str, &db);
    
    if (rc != SQLITE_OK) {
        // 打开失败，关闭数据库（如果有）
        if (db != NULL) {
            sqlite3_close(db);
        }
        return -1;
    }
    
    // 存储句柄并返回 ID
    return store_db(db);
}

/// SQLite 执行 SQL（适配 MoonBit FFI）
/// 
/// 参数：
/// - handle: 数据库连接句柄 ID
/// - sql: SQL 语句（MoonBit String）
/// 
/// 返回：
/// - 0: 成功
/// - 非0: 错误代码
int autumn_sqlite3_exec(int handle, moonbit_string_t sql) {
    sqlite3* db = get_db(handle);
    if (db == NULL) {
        return -1;
    }
    
    const char* sql_str = get_c_string(sql);
    
    // 调试：打印 SQL 语句（仅用于调试）
    // printf("DEBUG: Executing SQL: %s\n", sql_str);
    
    char* errmsg = NULL;
    int rc = sqlite3_exec(db, sql_str, NULL, NULL, &errmsg);
    
    // 如果执行失败，打印错误信息（用于调试）
    if (rc != SQLITE_OK && errmsg != NULL) {
        // printf("DEBUG: SQLite error: %s\n", errmsg);
        sqlite3_free(errmsg);
    } else if (errmsg != NULL) {
        sqlite3_free(errmsg);
    }
    
    return rc;
}

/// SQLite 执行带参数的 SQL（简化实现：暂时不支持）
int autumn_sqlite3_exec_prepared(int handle, moonbit_string_t sql, void* params) {
    // 暂时不支持参数，直接执行 SQL
    return autumn_sqlite3_exec(handle, sql);
}

/// SQLite 查询数据（实现完整的查询功能）
/// 
/// 参数：
/// - handle: 数据库连接句柄 ID
/// - sql: SQL 查询语句（MoonBit String）
/// - params: 参数数组（MoonBit Array[String]），暂时不使用
/// 
/// 返回：
/// - 查询结果数组（FixedArray[String]），每行是一个字符串，格式：column1=value1\tcolumn2=value2\t...
/// - 空数组表示查询失败或无结果
void** autumn_sqlite3_query(int handle, moonbit_string_t sql, void* params) {
    sqlite3* db = get_db(handle);
    void** results = moonbit_empty_ref_array;
    
    if (db == NULL) {
        return results;
    }
    
    // 转换 SQL 字符串
    const char* sql_str = get_c_string(sql);
    
    // 准备 SQL 语句
    sqlite3_stmt* stmt = NULL;
    int rc = sqlite3_prepare_v2(db, sql_str, -1, &stmt, NULL);
    
    if (rc != SQLITE_OK) {
        if (stmt != NULL) {
            sqlite3_finalize(stmt);
        }
        return results;
    }
    
    // 先收集所有行数据到临时数组
    #define MAX_ROWS 1000
    moonbit_string_t row_strings[MAX_ROWS];
    int row_count = 0;
    int num_columns = sqlite3_column_count(stmt);
    
    // 遍历结果集
    while ((rc = sqlite3_step(stmt)) == SQLITE_ROW && row_count < MAX_ROWS) {
        // 构建一行数据（格式：column1=value1\tcolumn2=value2\t...）
        char row_buffer[4096] = {0};
        int pos = 0;
        
        for (int i = 0; i < num_columns && pos < sizeof(row_buffer) - 1; i++) {
            if (i > 0 && pos < sizeof(row_buffer) - 1) {
                row_buffer[pos++] = '\t';
            }
            
            // 获取列名
            const char* column_name = sqlite3_column_name(stmt, i);
            if (column_name != NULL) {
                int name_len = strlen(column_name);
                if (pos + name_len + 1 < sizeof(row_buffer)) {
                    strcpy(row_buffer + pos, column_name);
                    pos += name_len;
                    row_buffer[pos++] = '=';
                }
            }
            
            // 获取列值
            const char* column_value = (const char*)sqlite3_column_text(stmt, i);
            if (column_value != NULL) {
                int value_len = strlen(column_value);
                if (pos + value_len < sizeof(row_buffer)) {
                    strncpy(row_buffer + pos, column_value, sizeof(row_buffer) - pos - 1);
                    pos += value_len;
                }
            }
        }
        
        // 创建 MoonBit String
        int str_len = strlen(row_buffer);
        moonbit_string_t row_str = moonbit_make_string_raw(str_len + 1);
        for (int i = 0; i < str_len; i++) {
            row_str[i] = (uint16_t)(unsigned char)row_buffer[i];
        }
        row_str[str_len] = 0;
        
        // 添加到结果数组
        row_strings[row_count++] = row_str;
    }
    
    // 释放语句
    sqlite3_finalize(stmt);
    
    // 如果没有结果，返回空数组
    if (row_count == 0) {
        return moonbit_empty_ref_array;
    }
    
    // 创建结果数组（使用 moonbit_make_ref_array）
    results = moonbit_make_ref_array(row_count, (void*)row_strings[0]);
    
    if (results == NULL) {
        return moonbit_empty_ref_array;
    }
    
    // 设置剩余元素（第一个元素已在创建时设置）
    void** array_elements = (void**)results;
    for (int i = 1; i < row_count; i++) {
        array_elements[i] = (void*)row_strings[i];
        moonbit_incref((void*)row_strings[i]);
    }
    
    return array_elements;
}

/// SQLite 关闭数据库连接（适配 MoonBit FFI）
/// 
/// 参数：
/// - handle: 数据库连接句柄 ID
/// 
/// 返回：
/// - 0: 成功
/// - 非0: 错误代码
int autumn_sqlite3_close(int handle) {
    sqlite3* db = get_db(handle);
    if (db == NULL) {
        return -1;
    }
    
    int rc = sqlite3_close(db);
    remove_db(handle);
    return rc;
}

/// SQLite 获取最后的错误信息（适配 MoonBit FFI）
/// 
/// 参数：
/// - handle: 数据库连接句柄 ID
/// 
/// 返回：
/// - 错误信息字符串（MoonBit String）
moonbit_string_t autumn_sqlite3_errmsg(int handle) {
    sqlite3* db = get_db(handle);
    if (db == NULL) {
        return moonbit_make_string_raw(0);
    }
    
    const char* errmsg = sqlite3_errmsg(db);
    if (errmsg == NULL || strlen(errmsg) == 0) {
        return moonbit_make_string_raw(0);
    }
    
    // UTF-8 到 UTF-16 转换（简化实现：仅处理 ASCII）
    int len = strlen(errmsg);
    moonbit_string_t result = moonbit_make_string_raw(len + 1); // +1 for NULL terminator
    
    // 将 UTF-8 ASCII 字符串转换为 UTF-16
    for (int i = 0; i < len; i++) {
        result[i] = (uint16_t)(unsigned char)errmsg[i]; // ASCII 字符直接转换
    }
    result[len] = 0; // NULL 终止符
    
    return result;
}
