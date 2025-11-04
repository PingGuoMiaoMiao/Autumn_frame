// database_ffi.c
// 
// 数据库 FFI 实现 - C 代码
// 
// 编译方式：
// 1. SQLite: gcc -shared -fPIC -o database_ffi.so database_ffi.c -lsqlite3
// 2. MySQL: gcc -shared -fPIC -o database_ffi.so database_ffi.c -lmysqlclient
// 3. PostgreSQL: gcc -shared -fPIC -o database_ffi.so database_ffi.c -lpq
//
// 注意：需要先安装 Moonbit 的 FFI 头文件（moonbit.h）

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

// Moonbit FFI 头文件（需要从 Moonbit SDK 获取）
// #include "moonbit.h"

// ========== SQLite 实现 ==========

#ifdef ENABLE_SQLITE
#include <sqlite3.h>

// SQLite 连接池（简化实现）
#define MAX_CONNECTIONS 10
static sqlite3* sqlite_connections[MAX_CONNECTIONS] = {NULL};

// 打开 SQLite 数据库
int32_t autumn_sqlite3_open(const char* filename) {
  sqlite3* db;
  int result = sqlite3_open(filename, &db);
  
  if (result != SQLITE_OK) {
    return -1;
  }
  
  // 查找空闲的槽位
  for (int i = 0; i < MAX_CONNECTIONS; i++) {
    if (sqlite_connections[i] == NULL) {
      sqlite_connections[i] = db;
      return i;  // 返回句柄（槽位索引）
    }
  }
  
  sqlite3_close(db);
  return -1;  // 连接池已满
}

// 执行 SQL 语句（不返回结果）
int32_t autumn_sqlite3_exec(int32_t handle, const char* sql) {
  if (handle < 0 || handle >= MAX_CONNECTIONS || sqlite_connections[handle] == NULL) {
    return -1;
  }
  
  sqlite3* db = sqlite_connections[handle];
  char* errmsg = NULL;
  
  int result = sqlite3_exec(db, sql, NULL, NULL, &errmsg);
  
  if (result != SQLITE_OK && errmsg != NULL) {
    fprintf(stderr, "SQLite error: %s\n", errmsg);
    sqlite3_free(errmsg);
    return result;
  }
  
  return 0;  // 成功
}

// 执行带参数的 SQL 语句（简化实现）
// 注意：实际实现需要使用 sqlite3_prepare_v2 和 sqlite3_bind_*
int32_t autumn_sqlite3_exec_prepared(int32_t handle, const char* sql, const char** params, int32_t param_count) {
  if (handle < 0 || handle >= MAX_CONNECTIONS || sqlite_connections[handle] == NULL) {
    return -1;
  }
  
  sqlite3* db = sqlite_connections[handle];
  sqlite3_stmt* stmt;
  
  int result = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
  if (result != SQLITE_OK) {
    return result;
  }
  
  // 绑定参数
  for (int i = 0; i < param_count; i++) {
    sqlite3_bind_text(stmt, i + 1, params[i], -1, SQLITE_TRANSIENT);
  }
  
  result = sqlite3_step(stmt);
  sqlite3_finalize(stmt);
  
  return (result == SQLITE_DONE) ? 0 : result;
}

// 查询数据（简化实现）
// 返回：每行用换行符分隔，列值用制表符分隔
// 注意：实际实现需要动态分配内存并返回给 Moonbit
const char* autumn_sqlite3_query(int32_t handle, const char* sql, const char** params, int32_t param_count) {
  if (handle < 0 || handle >= MAX_CONNECTIONS || sqlite_connections[handle] == NULL) {
    return NULL;
  }
  
  sqlite3* db = sqlite_connections[handle];
  sqlite3_stmt* stmt;
  
  int result = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
  if (result != SQLITE_OK) {
    return NULL;
  }
  
  // 绑定参数
  for (int i = 0; i < param_count; i++) {
    sqlite3_bind_text(stmt, i + 1, params[i], -1, SQLITE_TRANSIENT);
  }
  
  // 构建结果字符串（简化实现，实际需要动态分配）
  static char result_buffer[10240];  // 固定大小缓冲区
  result_buffer[0] = '\0';
  
  while ((result = sqlite3_step(stmt)) == SQLITE_ROW) {
    int col_count = sqlite3_column_count(stmt);
    
    for (int i = 0; i < col_count; i++) {
      if (i > 0) {
        strcat(result_buffer, "\t");
      }
      const char* value = (const char*)sqlite3_column_text(stmt, i);
      if (value != NULL) {
        strcat(result_buffer, value);
      }
    }
    strcat(result_buffer, "\n");
  }
  
  sqlite3_finalize(stmt);
  return result_buffer;
}

// 关闭数据库连接
int32_t autumn_sqlite3_close(int32_t handle) {
  if (handle < 0 || handle >= MAX_CONNECTIONS || sqlite_connections[handle] == NULL) {
    return -1;
  }
  
  sqlite3_close(sqlite_connections[handle]);
  sqlite_connections[handle] = NULL;
  return 0;
}

// 获取错误信息
const char* autumn_sqlite3_errmsg(int32_t handle) {
  if (handle < 0 || handle >= MAX_CONNECTIONS || sqlite_connections[handle] == NULL) {
    return "Invalid handle";
  }
  
  return sqlite3_errmsg(sqlite_connections[handle]);
}

#endif  // ENABLE_SQLITE

// ========== MySQL 实现 ==========

#ifdef ENABLE_MYSQL
#include <mysql/mysql.h>

// MySQL 连接池（简化实现）
static MYSQL* mysql_connections[MAX_CONNECTIONS] = {NULL};

// 连接到 MySQL 数据库
int32_t autumn_mysql_connect(const char* host, int32_t port, const char* user, const char* password, const char* database) {
  MYSQL* conn = mysql_init(NULL);
  
  if (conn == NULL) {
    return -1;
  }
  
  if (mysql_real_connect(conn, host, user, password, database, port, NULL, 0) == NULL) {
    mysql_close(conn);
    return -1;
  }
  
  // 查找空闲的槽位
  for (int i = 0; i < MAX_CONNECTIONS; i++) {
    if (mysql_connections[i] == NULL) {
      mysql_connections[i] = conn;
      return i;
    }
  }
  
  mysql_close(conn);
  return -1;
}

// 执行 SQL 语句
int32_t autumn_mysql_execute(int32_t handle, const char* sql) {
  if (handle < 0 || handle >= MAX_CONNECTIONS || mysql_connections[handle] == NULL) {
    return -1;
  }
  
  MYSQL* conn = mysql_connections[handle];
  
  if (mysql_query(conn, sql) != 0) {
    return -1;
  }
  
  return 0;
}

// 查询数据
const char* autumn_mysql_query(int32_t handle, const char* sql, const char** params, int32_t param_count) {
  if (handle < 0 || handle >= MAX_CONNECTIONS || mysql_connections[handle] == NULL) {
    return NULL;
  }
  
  MYSQL* conn = mysql_connections[handle];
  
  if (mysql_query(conn, sql) != 0) {
    return NULL;
  }
  
  MYSQL_RES* result = mysql_store_result(conn);
  if (result == NULL) {
    return NULL;
  }
  
  // 构建结果字符串（简化实现）
  static char result_buffer[10240];
  result_buffer[0] = '\0';
  
  MYSQL_ROW row;
  int num_fields = mysql_num_fields(result);
  
  while ((row = mysql_fetch_row(result))) {
    for (int i = 0; i < num_fields; i++) {
      if (i > 0) {
        strcat(result_buffer, "\t");
      }
      if (row[i] != NULL) {
        strcat(result_buffer, row[i]);
      }
    }
    strcat(result_buffer, "\n");
  }
  
  mysql_free_result(result);
  return result_buffer;
}

// 关闭数据库连接
int32_t autumn_mysql_close(int32_t handle) {
  if (handle < 0 || handle >= MAX_CONNECTIONS || mysql_connections[handle] == NULL) {
    return -1;
  }
  
  mysql_close(mysql_connections[handle]);
  mysql_connections[handle] = NULL;
  return 0;
}

// 获取错误信息
const char* autumn_mysql_errmsg(int32_t handle) {
  if (handle < 0 || handle >= MAX_CONNECTIONS || mysql_connections[handle] == NULL) {
    return "Invalid handle";
  }
  
  return mysql_error(mysql_connections[handle]);
}

#endif  // ENABLE_MYSQL

// ========== PostgreSQL 实现 ==========

#ifdef ENABLE_POSTGRES
#include <libpq-fe.h>

// PostgreSQL 连接池（简化实现）
static PGconn* pg_connections[MAX_CONNECTIONS] = {NULL};

// 连接到 PostgreSQL 数据库
int32_t autumn_pg_connect(const char* host, int32_t port, const char* user, const char* password, const char* database) {
  char conninfo[512];
  snprintf(conninfo, sizeof(conninfo), "host=%s port=%d user=%s password=%s dbname=%s", host, port, user, password, database);
  
  PGconn* conn = PQconnectdb(conninfo);
  
  if (PQstatus(conn) != CONNECTION_OK) {
    PQfinish(conn);
    return -1;
  }
  
  // 查找空闲的槽位
  for (int i = 0; i < MAX_CONNECTIONS; i++) {
    if (pg_connections[i] == NULL) {
      pg_connections[i] = conn;
      return i;
    }
  }
  
  PQfinish(conn);
  return -1;
}

// 执行 SQL 语句
int32_t autumn_pg_execute(int32_t handle, const char* sql, const char** params, int32_t param_count) {
  if (handle < 0 || handle >= MAX_CONNECTIONS || pg_connections[handle] == NULL) {
    return -1;
  }
  
  PGconn* conn = pg_connections[handle];
  PGresult* res = PQexecParams(conn, sql, param_count, NULL, params, NULL, NULL, 0);
  
  ExecStatusType status = PQresultStatus(res);
  PQclear(res);
  
  return (status == PGRES_COMMAND_OK || status == PGRES_TUPLES_OK) ? 0 : -1;
}

// 查询数据
const char* autumn_pg_query(int32_t handle, const char* sql, const char** params, int32_t param_count) {
  if (handle < 0 || handle >= MAX_CONNECTIONS || pg_connections[handle] == NULL) {
    return NULL;
  }
  
  PGconn* conn = pg_connections[handle];
  PGresult* res = PQexecParams(conn, sql, param_count, NULL, params, NULL, NULL, 0);
  
  if (PQresultStatus(res) != PGRES_TUPLES_OK) {
    PQclear(res);
    return NULL;
  }
  
  // 构建结果字符串（简化实现）
  static char result_buffer[10240];
  result_buffer[0] = '\0';
  
  int ntuples = PQntuples(res);
  int nfields = PQnfields(res);
  
  for (int i = 0; i < ntuples; i++) {
    for (int j = 0; j < nfields; j++) {
      if (j > 0) {
        strcat(result_buffer, "\t");
      }
      const char* value = PQgetvalue(res, i, j);
      if (value != NULL) {
        strcat(result_buffer, value);
      }
    }
    strcat(result_buffer, "\n");
  }
  
  PQclear(res);
  return result_buffer;
}

// 关闭数据库连接
int32_t autumn_pg_close(int32_t handle) {
  if (handle < 0 || handle >= MAX_CONNECTIONS || pg_connections[handle] == NULL) {
    return -1;
  }
  
  PQfinish(pg_connections[handle]);
  pg_connections[handle] = NULL;
  return 0;
}

// 获取错误信息
const char* autumn_pg_errmsg(int32_t handle) {
  if (handle < 0 || handle >= MAX_CONNECTIONS || pg_connections[handle] == NULL) {
    return "Invalid handle";
  }
  
  return PQerrorMessage(pg_connections[handle]);
}

#endif  // ENABLE_POSTGRES

