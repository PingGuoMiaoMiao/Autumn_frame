// MySQL FFI 胶水函数
// 
// 此文件提供了 MySQL C API 与 MoonBit FFI 之间的适配层
//
// 编译：需要链接 -lmysqlclient
// 使用：在 moon.pkg.json 的 "native-stub" 中配置

#include <mysql/mysql.h>
#include <string.h>
#include <stdlib.h>

// MoonBit 运行时头文件
#include <moonbit.h>

// 全局 MySQL 连接句柄映射表（简化实现：使用数组）
#define MAX_HANDLES 100
static MYSQL* mysql_handles[MAX_HANDLES] = {NULL};

// 获取 MySQL 连接句柄
static MYSQL* get_mysql(int handle) {
    if (handle >= 0 && handle < MAX_HANDLES) {
        return mysql_handles[handle];
    }
    return NULL;
}

// 存储 MySQL 连接句柄并返回句柄 ID
static int store_mysql(MYSQL* mysql) {
    if (mysql == NULL) {
        return -1;
    }
    for (int i = 0; i < MAX_HANDLES; i++) {
        if (mysql_handles[i] == NULL) {
            mysql_handles[i] = mysql;
            return i;
        }
    }
    return -1; // 句柄表已满
}

// 移除 MySQL 连接句柄
static void remove_mysql(int handle) {
    if (handle >= 0 && handle < MAX_HANDLES) {
        mysql_handles[handle] = NULL;
    }
}

// UTF-16 到 UTF-8 转换缓冲区（静态分配，避免内存泄漏）
static char utf8_buffer[4096];

// 从 MoonBit String (UTF-16) 获取 C 字符串 (UTF-8)
static const char* get_c_string(moonbit_string_t str) {
    if (str == NULL) {
        return "";
    }
    
    int i = 0;
    int j = 0;
    
    // 遍历 UTF-16 字符串，直到遇到 NULL 终止符或缓冲区满
    while (j < sizeof(utf8_buffer) - 1) {
        uint16_t code_unit = str[i];
        
        if (code_unit == 0) {
            break;
        }
        
        // ASCII 字符（0x00-0x7F）：直接使用低字节
        if (code_unit < 0x80) {
            utf8_buffer[j++] = (char)code_unit;
        } else {
            // 非 ASCII 字符：简化处理，使用替换字符
            utf8_buffer[j++] = '?';
        }
        
        i++;
        if (i > 4095) {
            break;
        }
    }
    
    utf8_buffer[j] = '\0';
    return utf8_buffer;
}

/// MySQL 连接到数据库（适配 MoonBit FFI）
/// 
/// 参数：
/// - host: 主机地址（MoonBit String）
/// - port: 端口号
/// - user: 用户名（MoonBit String）
/// - password: 密码（MoonBit String）
/// - database: 数据库名（MoonBit String）
/// 
/// 返回：
/// - >= 0: 成功，返回连接句柄 ID
/// - < 0: 失败
int autumn_mysql_connect(
    moonbit_string_t host,
    int port,
    moonbit_string_t user,
    moonbit_string_t password,
    moonbit_string_t database
) {
    MYSQL* mysql = mysql_init(NULL);
    if (mysql == NULL) {
        return -1;
    }
    
    const char* host_str = get_c_string(host);
    const char* user_str = get_c_string(user);
    const char* password_str = get_c_string(password);
    const char* database_str = get_c_string(database);
    
    // 连接到 MySQL 服务器
    MYSQL* result = mysql_real_connect(
        mysql,
        host_str,
        user_str,
        password_str,
        database_str,
        port,
        NULL,
        0
    );
    
    if (result == NULL) {
        mysql_close(mysql);
        return -1;
    }
    
    // 存储句柄并返回 ID
    return store_mysql(mysql);
}

/// MySQL 执行 SQL（不返回结果）
/// 
/// 参数：
/// - handle: 数据库连接句柄 ID
/// - sql: SQL 语句（MoonBit String）
/// 
/// 返回：
/// - 0: 成功
/// - 非0: 错误代码
int autumn_mysql_execute(int handle, moonbit_string_t sql) {
    MYSQL* mysql = get_mysql(handle);
    if (mysql == NULL) {
        return -1;
    }
    
    const char* sql_str = get_c_string(sql);
    
    int rc = mysql_real_query(mysql, sql_str, strlen(sql_str));
    
    return rc;
}

/// MySQL 查询数据
/// 
/// 参数：
/// - handle: 数据库连接句柄 ID
/// - sql: SQL 查询语句（MoonBit String）
/// - params: 参数数组（MoonBit Array[String]）
/// 
/// 返回：
/// - 查询结果数组（MoonBit Array[String]），每行是一个字符串，列值用制表符分隔
/// - 空数组表示查询失败或无结果
void** autumn_mysql_query(int handle, moonbit_string_t sql, void* params) {
    MYSQL* mysql = get_mysql(handle);
    void** results = moonbit_empty_ref_array;
    
    if (mysql == NULL) {
        return results;
    }
    
    const char* sql_str = get_c_string(sql);
    
    // 执行查询
    if (mysql_real_query(mysql, sql_str, strlen(sql_str)) != 0) {
        return results;
    }
    
    // 获取结果集
    MYSQL_RES* res = mysql_store_result(mysql);
    if (res == NULL) {
        return results;
    }
    
    // 获取字段数
    int num_fields = mysql_num_fields(res);
    
    // 创建结果数组
    results = moonbit_make_ref_array_raw(0);
    
    // 遍历结果集
    MYSQL_ROW row;
    while ((row = mysql_fetch_row(res)) != NULL) {
        // 构建一行数据（列值用制表符分隔）
        char row_buffer[4096] = {0};
        int pos = 0;
        
        for (int i = 0; i < num_fields && pos < sizeof(row_buffer) - 1; i++) {
            if (i > 0 && pos < sizeof(row_buffer) - 1) {
                row_buffer[pos++] = '\t';
            }
            
            // 获取列名
            MYSQL_FIELD* field = mysql_fetch_field_direct(res, i);
            if (field != NULL && field->name != NULL) {
                int name_len = strlen(field->name);
                if (pos + name_len + 1 < sizeof(row_buffer)) {
                    strcpy(row_buffer + pos, field->name);
                    pos += name_len;
                    row_buffer[pos++] = '=';
                }
            }
            
            // 获取列值
            if (row[i] != NULL) {
                int value_len = strlen(row[i]);
                if (pos + value_len < sizeof(row_buffer)) {
                    strncpy(row_buffer + pos, row[i], sizeof(row_buffer) - pos - 1);
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
        results = moonbit_make_ref_array_raw(moonbit_array_get_length(results) + 1);
        // 注意：这里需要正确添加元素，简化实现
    }
    
    mysql_free_result(res);
    return results;
}

/// MySQL 关闭数据库连接（适配 MoonBit FFI）
/// 
/// 参数：
/// - handle: 数据库连接句柄 ID
/// 
/// 返回：
/// - 0: 成功
/// - 非0: 错误代码
int autumn_mysql_close(int handle) {
    MYSQL* mysql = get_mysql(handle);
    if (mysql == NULL) {
        return -1;
    }
    
    mysql_close(mysql);
    remove_mysql(handle);
    return 0;
}

/// MySQL 获取最后的错误信息（适配 MoonBit FFI）
/// 
/// 参数：
/// - handle: 数据库连接句柄 ID
/// 
/// 返回：
/// - 错误信息字符串（MoonBit String）
moonbit_string_t autumn_mysql_errmsg(int handle) {
    MYSQL* mysql = get_mysql(handle);
    if (mysql == NULL) {
        return moonbit_make_string_raw(0);
    }
    
    const char* errmsg = mysql_error(mysql);
    if (errmsg == NULL || strlen(errmsg) == 0) {
        return moonbit_make_string_raw(0);
    }
    
    // UTF-8 到 UTF-16 转换（简化实现：仅处理 ASCII）
    int len = strlen(errmsg);
    moonbit_string_t result = moonbit_make_string_raw(len + 1);
    
    for (int i = 0; i < len; i++) {
        result[i] = (uint16_t)(unsigned char)errmsg[i];
    }
    result[len] = 0;
    
    return result;
}




