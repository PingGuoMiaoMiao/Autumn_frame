// HTTP 服务器 FFI 实现
// 用于 native 后端

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <errno.h>
#include <stdint.h>
#include <moonbit.h>

// 静态缓冲区用于 UTF-16 到 UTF-8 转换
static char utf8_buffer[8192];  // 8KB 缓冲区

// 创建 TCP socket 并绑定端口
int autumn_create_server_socket(int port) {
    int server_fd;
    struct sockaddr_in address;
    int opt = 1;

    // 创建 socket
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        perror("socket failed");
        return -1;
    }

    // 设置 socket 选项
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, &opt, sizeof(opt)) < 0) {
        perror("setsockopt failed");
        close(server_fd);
        return -1;
    }

    // 配置地址
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(port);

    // 绑定端口
    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("bind failed");
        close(server_fd);
        return -1;
    }

    // 开始监听
    if (listen(server_fd, 3) < 0) {
        perror("listen failed");
        close(server_fd);
        return -1;
    }

    printf("[C] Server socket created successfully on port %d\n", port);
    fflush(stdout);
    return server_fd;
}

// 接受连接
int autumn_accept_connection(int server_fd) {
    struct sockaddr_in address;
    socklen_t addrlen = sizeof(address);
    int new_socket = accept(server_fd, (struct sockaddr *)&address, &addrlen);
    if (new_socket >= 0) {
        printf("[C] Accepted connection from client (fd=%d)\n", new_socket);
        fflush(stdout);
    } else if (errno != EAGAIN && errno != EWOULDBLOCK) {
        // 忽略非阻塞 socket 的错误，其他错误记录
        perror("accept failed");
    }
    return new_socket;
}

// 读取请求（简化版，读取最多 4096 字节）
// 注意：MoonBit 的 String 在 FFI 中需要特殊处理
// 使用静态缓冲区存储读取的数据
static char request_buffer[4096];
static int request_buffer_len = 0;

// 读取请求到静态缓冲区，返回读取的字节数
int autumn_read_request(int client_fd) {
    // 读取数据到静态缓冲区
    int bytes_read = read(client_fd, request_buffer, sizeof(request_buffer) - 1);
    
    if (bytes_read > 0) {
        request_buffer[bytes_read] = '\0';
        request_buffer_len = bytes_read;
        printf("[C] Read %d bytes from client\n", bytes_read);
        printf("[C] First 100 chars: %.100s\n", request_buffer);
        fflush(stdout);
    } else if (bytes_read == 0) {
        printf("[C] Client closed connection\n");
        fflush(stdout);
        request_buffer[0] = '\0';
        request_buffer_len = 0;
    } else {
        perror("read failed");
        request_buffer[0] = '\0';
        request_buffer_len = 0;
    }
    
    return bytes_read;
}

// 获取读取的请求数据的某个字节
// 参数：index - 字节索引
// 返回：该位置的字节值，如果索引越界返回 -1
int autumn_get_request_byte(int index) {
    if (index >= 0 && index < request_buffer_len && index < sizeof(request_buffer)) {
        return (unsigned char)request_buffer[index];
    }
    return -1;
}

// 获取读取的字节数
int autumn_get_request_length() {
    return request_buffer_len;
}

// 从 MoonBit String (UTF-16) 转换为 C 字符串 (UTF-8)
// 
// 注意：moonbit_string_t 是 uint16_t*，指向 UTF-16 字符数组
// str_len 是 UTF-16 字符数（不是字节数）
// 参考 sqlite_wrapper.c 和 mysql_wrapper.c 的实现
static int moonbit_string_to_bytes(moonbit_string_t str, int str_len, char* buffer, int buffer_size) {
    if (str == NULL || buffer == NULL || buffer_size <= 0) {
        return 0;
    }
    
    // MoonBit String 是 uint16_t*，指向 UTF-16 字符数组
    // str_len 是 UTF-16 字符数（不是字节数）
    uint16_t* utf16_ptr = (uint16_t*)str;
    int utf8_idx = 0;
    int utf16_idx = 0;
    int max_len = buffer_size - 1;
    
    // 遍历 UTF-16 字符串，转换为 UTF-8
    // 使用 str_len 作为最大字符数（UTF-16 代码单元数），防止越界
    // 注意：MoonBit 字符串可能不是 NULL 终止的，完全依赖 str_len
    while (utf16_idx < str_len && utf8_idx < max_len) {
        uint16_t code_unit = utf16_ptr[utf16_idx];
        
        // ASCII 字符（0x00-0x7F）：直接使用
        if (code_unit < 0x80) {
            buffer[utf8_idx++] = (char)code_unit;
        } else if (code_unit < 0x800) {
            // 2 字节 UTF-8 字符
            if (utf8_idx + 1 < max_len) {
                buffer[utf8_idx++] = (char)(0xC0 | (code_unit >> 6));
                buffer[utf8_idx++] = (char)(0x80 | (code_unit & 0x3F));
            } else {
                break;  // 缓冲区不足
            }
        } else {
            // 3 字节或更多（简化处理）
            if (utf8_idx + 2 < max_len) {
                buffer[utf8_idx++] = (char)(0xE0 | (code_unit >> 12));
                buffer[utf8_idx++] = (char)(0x80 | ((code_unit >> 6) & 0x3F));
                buffer[utf8_idx++] = (char)(0x80 | (code_unit & 0x3F));
            } else {
                break;  // 缓冲区不足
            }
        }
        
        utf16_idx++;
    }
    
    buffer[utf8_idx] = '\0';  // 确保 NULL 终止
    return utf8_idx;
}

// 发送响应
// 注意：MoonBit String 在 FFI 中需要特殊处理
// 在 native 后端，MoonBit 字符串可能是 UTF-16 编码的
int autumn_send_response(int client_fd, moonbit_string_t response, int response_len) {
    if (response == NULL) {
        printf("[C] Error: response is NULL\n");
        return -1;
    }
    
    // 转换 MoonBit 字符串为 UTF-8 字节数组
    int utf8_len = moonbit_string_to_bytes(response, response_len, utf8_buffer, sizeof(utf8_buffer));
    
    if (utf8_len <= 0) {
        printf("[C] Error: Failed to convert MoonBit string to UTF-8\n");
        return -1;
    }
    
    // 调试：打印响应内容
    printf("[C] Sending response (MoonBit length=%d, UTF-8 bytes=%d):\n", response_len, utf8_len);
    printf("[C] First 100 bytes (hex): ");
    int print_len = (utf8_len > 100) ? 100 : utf8_len;
    for (int i = 0; i < print_len; i++) {
        printf("%02x ", (unsigned char)utf8_buffer[i]);
        if ((i + 1) % 16 == 0) printf("\n[C]                      ");
    }
    printf("\n[C] First 100 bytes (ASCII, escaped): ");
    for (int i = 0; i < print_len; i++) {
        unsigned char c = (unsigned char)utf8_buffer[i];
        if (c >= 32 && c < 127 && c != '\r' && c != '\n') {
            printf("%c", c);
        } else if (c == '\r') {
            printf("\\r");
        } else if (c == '\n') {
            printf("\\n");
        } else {
            printf("\\x%02x", c);
        }
    }
    printf("\n[C] First 100 bytes (raw): ");
    fwrite(utf8_buffer, 1, print_len, stdout);
    printf("\n");
    fflush(stdout);
    
    // 发送响应
    ssize_t bytes_sent = send(client_fd, utf8_buffer, utf8_len, 0);
    if (bytes_sent > 0) {
        printf("[C] Sent %zd bytes to client (expected %d)\n", bytes_sent, utf8_len);
        fflush(stdout);
    } else if (bytes_sent < 0) {
        perror("send failed");
    } else {
        printf("[C] Warning: send returned 0 bytes\n");
        fflush(stdout);
    }
    return (int)bytes_sent;
}

// 关闭连接
void autumn_close_connection(int fd) {
    close(fd);
}

// 关闭服务器
void autumn_close_server(int server_fd) {
    close(server_fd);
}

