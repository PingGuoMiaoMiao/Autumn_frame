# ResourceResolver 使用说明

## 概述

`ResourceResolver` 是一个资源扫描器，模仿 Java 的 classpath 资源扫描功能，可以在给定的包路径下递归扫描文件资源。

## 核心类型

### Resource

表示一个被发现的资源文件：

```moonbit
pub struct Resource {
  path : String  // 完整路径，带 "file:" 前缀
  name : String  // 相对于包根目录的相对路径名
}
```

### ResourceResolver

资源扫描器：

```moonbit
pub struct ResourceResolver {
  base_package : String  // 基础包名，如 "com.example.config"
}
```

## API

### 创建 ResourceResolver

```moonbit
let resolver = ResourceResolver::new("com.example.config")
```

将包名中的 `.` 转换为 `/`，然后扫描 `./com/example/config/` 目录。

### 扫描资源

```moonbit
pub fn [T] ResourceResolver::scan(
  self : ResourceResolver, 
  mapper : (Resource) -> T?
) -> @list.List[T]
```

- **参数**:
  - `mapper`: 映射函数，接收 `Resource`，返回 `T?`
    - 返回 `Some(value)` 表示收集该资源
    - 返回 `None` 表示跳过该资源

- **返回值**: 返回收集到的所有 `T` 值的列表（`@list.List[T]`）

## 使用示例

### 示例 1: 扫描所有 JSON 文件

```moonbit
let resolver = ResourceResolver::new("config")

let json_files : @list.List[String] = resolver.scan(fn(res : Resource) -> String? {
  if res.name.has_suffix(".json") {
    Some(res.path)  // 收集路径
  } else {
    None            // 跳过非 JSON 文件
  }
})

println("找到 \{json_files.length()} 个 JSON 文件")
```

### 示例 2: 收集所有资源对象

```moonbit
let all_resources : @list.List[Resource] = resolver.scan(fn(res : Resource) -> Resource? {
  Some(res)  // 收集所有资源
})
```

### 示例 3: 过滤特定文件名

```moonbit
let main_files = resolver.scan(fn(res : Resource) -> Resource? {
  if res.name == "main.mbt" {
    Some(res)  // 只收集 main.mbt
  } else {
    None
  }
})

// 遍历结果
let _ = main_files.map(fn(resource) {
  println("找到: \{resource.path}")
})
```

### 示例 4: 自定义数据转换

```moonbit
// 定义配置结构
struct ConfigFile {
  name : String
  full_path : String
}

let configs : @list.List[ConfigFile] = resolver.scan(fn(res : Resource) -> ConfigFile? {
  if res.name.has_suffix(".conf") {
    Some({ name: res.name, full_path: res.path })
  } else {
    None
  }
})
```

## 实现细节

### 文件系统 API

使用 `.mooncakes/moonbitlang/x/fs` 提供的 API:

- `@fs.path_exists(path : String) -> Bool`
- `@fs.read_dir(path : String) -> Array[String] raise IOError`
- `@fs.is_dir(path : String) -> Bool raise IOError`
- `@fs.is_file(path : String) -> Bool raise IOError`

### 扫描策略

1. 将包名 `com.example.config` 转换为路径 `com/example/config`
2. 从当前工作目录的相对路径 `./com/example/config` 开始扫描
3. 递归遍历所有子目录
4. 对每个文件调用 `mapper` 函数
5. 收集 `mapper` 返回 `Some(value)` 的结果

### 错误处理

- 使用 `try/catch` 捕获文件系统操作的 `IOError`
- 遇到错误时跳过该文件/目录，继续扫描其他资源
- 不会中断整个扫描过程

### 列表构建

使用函数式风格构建列表:

1. 使用 `@list.cons(value, accumulator)` 前插元素（O(1) 操作）
2. 最后调用 `.rev()` 反转列表，恢复正确顺序

## 限制与未来扩展

### 当前限制

- **仅支持文件系统**: 当前只扫描文件系统目录
- **不支持 JAR/ZIP**: 不会自动扫描 jar 或 zip 压缩包内的资源
- **相对路径**: 只扫描相对于当前工作目录的路径

### 未来可能的扩展

- 添加 ZIP 归档支持（需要 zip 解压库）
- 支持绝对路径扫描
- 添加路径排除规则（如 `.git`、`node_modules`）
- 缓存扫描结果提高性能

## 测试

运行测试:

```bash
moon test --target wasm-gc
```

查看 `ResourceResolver_test.mbt` 获取更多示例。

## 与 Java 版本的对比

| 特性 | Java 版本 | Moonbit 版本 |
|------|----------|--------------|
| 文件系统扫描 | ✅ | ✅ |
| JAR/ZIP 扫描 | ✅ | ❌ (未实现) |
| 过滤器/映射器 | ✅ | ✅ |
| 错误处理 | 异常 | try/catch |
| 数据结构 | List/Stream | @list.List |

## 依赖

- **moonbitlang/x/fs**: 文件系统操作
- **@list**: Moonbit 核心库的列表类型
