// MySQL FFI 胶水函数
// 
// 此文件提供了 MySQL C API 与 MoonBit FFI 之间的适配层
//
// 编译：需要链接 -lmysqlclient
// 使用：在 moon.pkg.json 的 "native-stub" 中配置

#include <mysql/mysql.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

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
// 使用多个缓冲区避免重复调用时的覆盖问题
static char utf8_buffer_1[4096];
static char utf8_buffer_2[4096];
static char utf8_buffer_3[4096];
static char utf8_buffer_4[4096];
static char utf8_buffer_5[4096];
static int buffer_counter = 0;

// 从 MoonBit String (UTF-16) 获取 C 字符串 (UTF-8)
// 使用独立缓冲区参数，避免覆盖
// 注意：moonbit_string_t 是 uint16_t*，指向 UTF-16 字符数组
// MoonBit String 可能不是 NULL 终止的，需要根据实际布局处理
// 参考 SQLite wrapper 的实现
static const char* get_c_string_to_buffer(moonbit_string_t str, char* buffer, size_t buffer_size) {
    if (str == NULL) {
        buffer[0] = '\0';
        return buffer;
    }
    
    // MoonBit String 是 uint16_t*，指向 UTF-16 字符数组
    // 字符串可能不是 NULL 终止的，需要检查实际长度
    // 简化实现：假设字符串是 NULL 终止的，或者有合理的长度限制
    
    int i = 0;
    int j = 0;
    int max_len = (int)(buffer_size - 1);
    
    // 遍历 UTF-16 字符串，直到遇到 NULL 终止符或缓冲区满
    while (j < max_len && i < 4095) {
        uint16_t code_unit = str[i];
        
        // 检查是否是 NULL 终止符
        if (code_unit == 0) {
            break;
        }
        
        // ASCII 字符（0x00-0x7F）：直接使用低字节
        if (code_unit < 0x80) {
            buffer[j++] = (char)code_unit;
        } else if (code_unit < 0x800) {
            // 2 字节 UTF-8 字符（简化实现）
            if (j + 1 < max_len) {
                buffer[j++] = (char)(0xC0 | (code_unit >> 6));
                buffer[j++] = (char)(0x80 | (code_unit & 0x3F));
            } else {
                break;
            }
        } else {
            // 3 字节或更多（简化处理，使用替换字符）
            buffer[j++] = '?';
        }
        
        i++;
    }
    
    buffer[j] = '\0'; // 确保 NULL 终止
    return buffer;
}

// 兼容旧接口（使用静态缓冲区，用于单个字符串转换）
static const char* get_c_string(moonbit_string_t str) {
    static char static_buffer[4096];
    return get_c_string_to_buffer(str, static_buffer, sizeof(static_buffer));
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
    
    // 为每个字符串单独分配缓冲区（避免覆盖）
    char host_buffer[256];
    char user_buffer[256];
    char password_buffer[256];
    char database_buffer[256];
    
    // 调试：先打印原始指针地址
    fprintf(stderr, "DEBUG: Raw pointers: host=%p, user=%p, password=%p, database=%p\n",
           (void*)host, (void*)user, (void*)password, (void*)database);
    fflush(stderr);
    
    // 先转换所有字符串到独立缓冲区，然后立即使用
    // 注意：必须在调用 mysql_real_connect 之前完成所有转换
    // 注意：每个字符串转换后，立即复制到独立缓冲区，避免覆盖
    get_c_string_to_buffer(host, host_buffer, sizeof(host_buffer));
    get_c_string_to_buffer(user, user_buffer, sizeof(user_buffer));
    get_c_string_to_buffer(password, password_buffer, sizeof(password_buffer));
    get_c_string_to_buffer(database, database_buffer, sizeof(database_buffer));
    
    // 调试输出（用于排查问题）
    fflush(stdout);  // 确保输出被刷新
    fprintf(stderr, "DEBUG: After conversion: host='%s', port=%d, user='%s', password='%s', database='%s'\n", 
           host_buffer, port, user_buffer, password_buffer, database_buffer);
    fprintf(stderr, "DEBUG: Buffer addresses: host=%p, user=%p, password=%p, database=%p\n",
           host_buffer, user_buffer, password_buffer, database_buffer);
    
    // 调试：检查每个字符串的前几个字符
    fprintf(stderr, "DEBUG: First chars - host[0]=%d, user[0]=%d, password[0]=%d, database[0]=%d\n",
           host ? (int)host[0] : -1,
           user ? (int)user[0] : -1,
           password ? (int)password[0] : -1,
           database ? (int)database[0] : -1);
    fflush(stderr);
    
    // 连接到 MySQL 服务器
    MYSQL* result = mysql_real_connect(
        mysql,
        host_buffer,
        user_buffer,
        password_buffer,
        database_buffer,
        port,
        NULL,
        0
    );
    
    if (result == NULL) {
        // 获取错误信息用于调试
        fprintf(stderr, "DEBUG: MySQL connection failed: %s\n", mysql_error(mysql));
        fflush(stderr);
        mysql_close(mysql);
        return -1;
    }
    
    fprintf(stderr, "DEBUG: MySQL connection successful!\n");
    fflush(stderr);
    
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
// 返回 FixedArray[String] 而不是 Array[String]
// FixedArray 在内存中是一块连续的 T 类型元素，可以直接传递给 C
void** autumn_mysql_query(int handle, moonbit_string_t sql, void* params) {
    fprintf(stderr, "DEBUG: autumn_mysql_query called with handle=%d\n", handle);
    fflush(stderr);
    
    MYSQL* mysql = get_mysql(handle);
    void** results = moonbit_empty_ref_array;
    
    if (mysql == NULL) {
        fprintf(stderr, "DEBUG: mysql is NULL, returning empty array\n");
        fflush(stderr);
        return results;
    }
    
    fprintf(stderr, "DEBUG: mysql is valid, proceeding with query\n");
    fflush(stderr);
    
    // 转换 SQL 字符串
    char sql_buffer[4096];
    get_c_string_to_buffer(sql, sql_buffer, sizeof(sql_buffer));
    
    fprintf(stderr, "DEBUG: Executing SQL: %s\n", sql_buffer);
    fflush(stderr);
    
    // 执行查询
    if (mysql_real_query(mysql, sql_buffer, strlen(sql_buffer)) != 0) {
        fprintf(stderr, "DEBUG: mysql_real_query failed: %s\n", mysql_error(mysql));
        fflush(stderr);
        return moonbit_empty_ref_array;
    }
    
    // 获取结果集
    MYSQL_RES* res = mysql_store_result(mysql);
    if (res == NULL) {
        fprintf(stderr, "DEBUG: mysql_store_result returned NULL, error: %s\n", mysql_error(mysql));
        fflush(stderr);
        return moonbit_empty_ref_array;
    }
    
    // 获取字段数和字段信息
    int num_fields = mysql_num_fields(res);
    MYSQL_FIELD* fields = mysql_fetch_fields(res);
    
    fprintf(stderr, "DEBUG: Query executed successfully, num_fields=%d\n", num_fields);
    fflush(stderr);
    
    // 先收集所有行数据到临时数组
    #define MAX_ROWS 1000
    moonbit_string_t row_strings[MAX_ROWS];
    int row_count = 0;
    
    // 遍历结果集
    MYSQL_ROW row;
    fprintf(stderr, "DEBUG: Starting to fetch rows...\n");
    fflush(stderr);
    while ((row = mysql_fetch_row(res)) != NULL && row_count < MAX_ROWS) {
        if (row_count == 0) {
            fprintf(stderr, "DEBUG: First row fetched\n");
            fflush(stderr);
        }
        // 构建一行数据（格式：column1=value1\tcolumn2=value2\t...）
        char row_buffer[4096] = {0};
        int pos = 0;
        
        for (int i = 0; i < num_fields && pos < sizeof(row_buffer) - 1; i++) {
            if (i > 0 && pos < sizeof(row_buffer) - 1) {
                row_buffer[pos++] = '\t';
            }
            
            // 添加列名
            if (fields[i].name != NULL) {
                int name_len = strlen(fields[i].name);
                if (pos + name_len + 1 < sizeof(row_buffer)) {
                    strncpy(row_buffer + pos, fields[i].name, sizeof(row_buffer) - pos - 1);
                    pos += name_len;
                    row_buffer[pos++] = '=';
                }
            }
            
            // 添加列值
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
        
        // 保存到临时数组
        row_strings[row_count++] = row_str;
    }
    
    // 释放结果集
    mysql_free_result(res);
    
    // 创建结果数组
    fprintf(stderr, "DEBUG: About to create array, row_count=%d\n", row_count);
    fflush(stderr);
    
    if (row_count > 0) {
        // 使用 moonbit_make_ref_array 创建数组，初始化为第一个字符串
        // 这样可以确保对象头被正确初始化
        fprintf(stderr, "DEBUG: Calling moonbit_make_ref_array with len=%d\n", row_count);
        fflush(stderr);
        results = moonbit_make_ref_array(row_count, (void*)row_strings[0]);
        
        if (results == NULL) {
            fprintf(stderr, "DEBUG: moonbit_make_ref_array returned NULL!\n");
            fflush(stderr);
            return moonbit_empty_ref_array;
        }
        
        fprintf(stderr, "DEBUG: Array created successfully at %p\n", (void*)results);
        fflush(stderr);
        
        // moonbit_make_ref_array 返回的是指向数组元素起始位置的指针
        // 对象头在数组元素之前
        // 注意：MoonBit 运行时期望接收的是数组元素指针，而不是对象头指针
        struct moonbit_object* obj_header = (struct moonbit_object*)((char*)results - sizeof(struct moonbit_object));
        void** array_elements = (void**)results;
        
        fprintf(stderr, "DEBUG: results pointer=%p, obj_header=%p, offset=%ld\n",
               (void*)results, (void*)obj_header, (char*)results - (char*)obj_header);
        fflush(stderr);
        
        fprintf(stderr, "DEBUG: Object header at %p, array elements at %p\n", 
               (void*)obj_header, (void*)array_elements);
        fprintf(stderr, "DEBUG: Object header meta=0x%x, rc=%d\n", 
               obj_header->meta, obj_header->rc);
        
        // 验证 meta 字段格式
        uint32_t kind = obj_header->meta >> 30;
        uint32_t object_size_shift = (obj_header->meta >> 28) & 3;
        uint32_t len = obj_header->meta & 0x0FFFFFFF;
        fprintf(stderr, "DEBUG: Parsed meta - kind=%u, object_size_shift=%u, len=%u\n",
               kind, object_size_shift, len);
        
        // 对于 64 位系统上的引用数组，object_size_shift 应该是 3 (log2(sizeof(void*)) = 3)
        // 如果 object_size_shift 不正确，需要修正
        if (kind == 1 && object_size_shift != 3) {
            fprintf(stderr, "DEBUG: WARNING - object_size_shift should be 3 for 64-bit ref array, got %u\n", object_size_shift);
            // 修正 meta 字段
            uint32_t correct_meta = (1 << 30) | (3 << 28) | len;
            fprintf(stderr, "DEBUG: Correcting meta from 0x%x to 0x%x\n", obj_header->meta, correct_meta);
            obj_header->meta = correct_meta;
        }
        fflush(stderr);
        
        // 更新所有数组元素
        // 注意：第一个元素已经在创建时设置并增加了引用计数，不需要再处理
        // 其他元素需要手动设置并增加引用计数
        for (int i = 1; i < row_count; i++) {
            fprintf(stderr, "DEBUG: Setting array[%d] = %p\n", i, (void*)row_strings[i]);
            fflush(stderr);
            
            // 设置元素
            array_elements[i] = (void*)row_strings[i];
            
            // 增加引用计数（字符串会被数组引用）
            moonbit_incref((void*)row_strings[i]);
        }
        
        // 第一个元素已经在创建时正确设置，不需要再处理
        fprintf(stderr, "DEBUG: Element[0] already set to %p by moonbit_make_ref_array\n", 
               (void*)array_elements[0]);
        fflush(stderr);
        
        fprintf(stderr, "DEBUG: Created array with %d rows successfully\n", row_count);
        fflush(stderr);
        
        // 根据 MoonBit FFI 文档，Array[String] 返回类型对应 void**，指向数组元素
        // 但实际测试发现，MoonBit 运行时可能期望接收对象头指针
        // 根据 Moonbit_object_header 宏定义：((struct moonbit_object*)(obj) - 1)
        // 这意味着如果传入数组元素指针，MoonBit 会减去 sizeof(struct moonbit_object*) 来找到对象头
        // 但我们的对象头在数组元素之前 sizeof(struct moonbit_object) 字节处
        // 所以我们需要返回数组元素指针，让 MoonBit 运行时自动找到对象头
        
        fprintf(stderr, "DEBUG: Returning array elements pointer at %p\n", (void*)array_elements);
        fprintf(stderr, "DEBUG: Final check - meta=0x%x, rc=%d, len from meta=%u, expected=%d\n", 
               obj_header->meta, obj_header->rc, obj_header->meta & 0x0FFFFFFF, row_count);
        
        // 验证数组元素是否正确设置
        for (int i = 0; i < row_count && i < 3; i++) {
            fprintf(stderr, "DEBUG: array[%d] = %p\n", i, (void*)array_elements[i]);
        }
        
        // 验证对象头布局（使用 MoonBit 的宏）
        fprintf(stderr, "DEBUG: Using Moonbit_object_header macro: %p\n", 
               (void*)Moonbit_object_header((void*)array_elements));
        fprintf(stderr, "DEBUG: Array length from macro: %u\n", 
               Moonbit_array_length((void*)array_elements));
        fflush(stderr);
        
        // 根据 MoonBit FFI 官方文档：
        // 1. FixedArray[T] 在 C 中映射为 T*（指向数组元素的指针）
        // 2. Array[T] 的映射方式在文档中未明确提及，可能不支持直接返回
        // 3. Moonbit_object_header 宏期望传入数组元素指针，然后减去 1 找到对象头
        // 
        // 当前问题：返回数组元素指针时，MoonBit 运行时无法正确读取数组长度
        // 可能原因：Array[T] 在 FFI 中可能不支持直接返回，需要使用 FixedArray[T]
        // 
        // 返回数组元素指针（这是文档建议的方式）
        // 如果问题仍然存在，可能需要：
        // 1. 修改 FFI 函数签名，返回 FixedArray[String] 而不是 Array[String]
        // 2. 在 MoonBit 侧使用 Array::from_iter 转换
        return array_elements;
    } else {
        fprintf(stderr, "DEBUG: No rows found, returning empty array\n");
        fflush(stderr);
        return moonbit_empty_ref_array;
    }
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

