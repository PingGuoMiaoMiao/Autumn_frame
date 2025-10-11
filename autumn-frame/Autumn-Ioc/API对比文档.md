# Java ResourceResolver vs Moonbit 实现对比

## 📊 完整 API 对比表

| 功能分类 | Java API | Moonbit API | 实现状态 |
|---------|----------|-------------|----------|
| **核心类** | `ResourceResolver` | `ResourceResolver` | ✅ 已实现 |
| **数据结构** | `Resource(String path, String name)` | `Resource { path: String, name: String }` | ✅ 已实现 |
| **构造函数** | `new ResourceResolver(String basePackage)` | `ResourceResolver::new(base_package: String)` | ✅ 已实现 |
| **扫描方法** | `scan(Function<Resource, R> mapper)` | `scan[T](mapper: (Resource) -> T?)` | ✅ 已实现 |
| **文件系统扫描** | `scanFile(...)` 递归扫描 | `scan_dir(...)` 递归扫描 | ✅ 已实现 |
| **JAR/ZIP 扫描** | `jarUriToPath(...)` + `FileSystems` | ❌ 未实现 | ⚠️ 需要 ZIP 库 |
| **ClassLoader** | `getContextClassLoader()` | ❌ 不适用 | ⛔ 概念不存在 |
| **URL/URI 解析** | `getResources(path)` | ❌ 不适用 | ⛔ 无类路径 |
| **路径规范化** | `removeLeadingSlash()` | `remove_leading_slash()` | ✅ 已实现 |
| | `removeTrailingSlash()` | `remove_trailing_slash()` | ✅ 已实现 |
| | - | `normalize_path()` | ✅ 额外添加 |
| | - | `join_path()` | ✅ 额外添加 |
| **URL 解码** | `URLDecoder.decode()` | ❌ 未实现 | ⚠️ 可选功能 |
| **日志记录** | `logger.atDebug().log()` | ❌ 未实现 | ⚠️ 可选功能 |

## 🔍 详细功能对比

### 1. 核心扫描逻辑

#### Java 版本
```java
public <R> List<R> scan(Function<Resource, R> mapper) {
    String basePackagePath = this.basePackage.replace(".", "/");
    List<R> collector = new ArrayList<>();
    // 通过 ClassLoader 获取所有匹配的 URL
    Enumeration<URL> en = getContextClassLoader().getResources(path);
    while (en.hasMoreElements()) {
        URL url = en.nextElement();
        // 可能是文件系统或 JAR
        if (uriStr.startsWith("jar:")) {
            scanFile(true, ...);  // JAR 扫描
        } else {
            scanFile(false, ...); // 文件系统扫描
        }
    }
    return collector;
}
```

#### Moonbit 版本
```moonbit
pub fn [T] ResourceResolver::scan(
  self : ResourceResolver, 
  mapper : (Resource) -> T?
) -> @list.List[T] {
  let base_package_path = self.base_package.replace(old=".", new="/")
  let mut collector : @list.List[T] = @list.empty()
  
  // 只扫描文件系统（相对路径）
  let candidate = "./" + base_package_path
  if @fs.path_exists(candidate) {
    try {
      if @fs.is_dir(candidate) {
        collector = scan_dir(candidate, candidate, collector, mapper)
      }
    } catch {
      _ => ()
    }
  }
  
  return collector.rev()
}
```

**差异点：**
- ✅ Java: 支持多资源源（文件、JAR、网络），通过 ClassLoader 自动发现
- ⚠️ Moonbit: 仅支持单一文件系统源，硬编码相对路径

### 2. JAR/ZIP 扫描

#### Java 版本
```java
Path jarUriToPath(String basePackagePath, URI jarUri) throws IOException {
    // 打开 JAR 文件系统并返回路径
    return FileSystems.newFileSystem(jarUri, Map.of())
                      .getPath(basePackagePath);
}

// 在 scan0 中使用
if (uriStr.startsWith("jar:")) {
    scanFile(true, uriBaseStr, jarUriToPath(basePackagePath, uri), collector, mapper);
}
```

#### Moonbit 版本
```moonbit
// 当前未实现
// 注释：不自动扫描 jar/zip（可以后续按需添加 zip 支持）
```

**状态：** ❌ **未实现**
- 需要 Moonbit 的 ZIP 解压库支持
- 需要设计 JAR 文件识别机制

### 3. 路径工具函数

#### Java 版本
```java
String removeLeadingSlash(String s) {
    if (s.startsWith("/") || s.startsWith("\\")) {
        s = s.substring(1);
    }
    return s;
}

String removeTrailingSlash(String s) {
    if (s.endsWith("/") || s.endsWith("\\")) {
        s = s.substring(0, s.length() - 1);
    }
    return s;
}

String uriToString(URI uri) {
    return URLDecoder.decode(uri.toString(), StandardCharsets.UTF_8);
}
```

#### Moonbit 版本
```moonbit
// PathUtils.mbt
pub fn remove_leading_slash(s : String) -> String {
  if s.has_prefix("/") || s.has_prefix("\\") {
    try { s[1:].to_string() } catch { _ => s }
  } else {
    s
  }
}

pub fn remove_trailing_slash(s : String) -> String {
  let len = s.length()
  if len > 0 && (s.has_suffix("/") || s.has_suffix("\\")) {
    try { s[0:len - 1].to_string() } catch { _ => s }
  } else {
    s
  }
}

pub fn normalize_path(s : String) -> String {
  s |> remove_leading_slash |> remove_trailing_slash
}

pub fn join_path(base : String, name : String) -> String {
  // 智能连接路径片段
}
```

**对比：**
- ✅ Moonbit 实现了基本的路径规范化
- ✅ Moonbit 额外提供了 `normalize_path()` 和 `join_path()`
- ❌ Moonbit 缺少 URL 解码功能（`uriToString`）

### 4. 错误处理

#### Java 版本
```java
public <R> List<R> scan(Function<Resource, R> mapper) {
    try {
        // ... 扫描逻辑
    } catch (IOException e) {
        throw new UncheckedIOException(e);
    } catch (URISyntaxException e) {
        throw new RuntimeException(e);
    }
}
```

#### Moonbit 版本
```moonbit
pub fn [T] ResourceResolver::scan(...) -> @list.List[T] {
  // ...
  try {
    if @fs.is_dir(candidate) {
      collector = scan_dir(candidate, candidate, collector, mapper)
    }
  } catch {
    _ => ()  // 静默忽略错误
  }
  // ...
}
```

**对比：**
- Java: 抛出异常让调用者处理
- Moonbit: 静默捕获错误并继续（更宽容）

### 5. 日志记录

#### Java 版本
```java
Logger logger = LoggerFactory.getLogger(getClass());

<R> void scan0(...) throws IOException, URISyntaxException {
    logger.atDebug().log("scan path: {}", path);
    // ...
}

<R> void scanFile(...) throws IOException {
    // ...
    logger.atDebug().log("found resource: {}", res);
    // ...
}
```

#### Moonbit 版本
```moonbit
// 当前未实现日志功能
// 可以使用 println 进行调试：
// println("scan path: \{path}")
```

**状态：** ❌ **未实现**
- Moonbit 没有标准日志库
- 可以用 `println` 临时调试

## 📋 功能清单

### ✅ 已完全实现
1. ✅ 基础资源扫描（文件系统）
2. ✅ 递归目录遍历
3. ✅ 泛型 mapper 过滤机制
4. ✅ 路径规范化工具
5. ✅ 错误处理（try/catch）
6. ✅ 函数式列表构建

### ⚠️ 部分实现/简化
1. ⚠️ 只支持单一文件系统源（Java 支持多源）
2. ⚠️ 硬编码相对路径（Java 使用 ClassLoader 动态发现）
3. ⚠️ 缺少 URL 解码（Java 有 `URLDecoder`）

### ❌ 未实现/不适用
1. ❌ JAR/ZIP 归档扫描（需要 ZIP 库）
2. ⛔ ClassLoader 集成（Moonbit 无此概念）
3. ⛔ 类路径资源发现（Moonbit 无类路径）
4. ❌ 日志记录（无标准日志库）

## 🎯 核心差异总结

| 维度 | Java 版本 | Moonbit 版本 |
|-----|-----------|--------------|
| **设计哲学** | 基于 ClassLoader 的动态资源发现 | 基于文件系统的静态扫描 |
| **资源源** | 文件系统 + JAR + 网络 | 仅文件系统 |
| **路径解析** | 自动通过 ClassLoader | 硬编码相对路径 |
| **归档支持** | ✅ JAR/ZIP 完整支持 | ❌ 需要额外实现 |
| **错误策略** | 抛出异常 | 静默忽略 |
| **日志** | SLF4J 集成 | 无 |
| **类型系统** | 泛型 + null | 泛型 + Option |

## 🚀 使用建议

### 什么时候可以直接替换？
- ✅ 只扫描文件系统资源
- ✅ 使用相对路径
- ✅ 不需要 JAR 包内资源
- ✅ 可以接受静默错误处理

### 什么时候需要扩展？
- ⚠️ 需要扫描 JAR/ZIP 文件 → 添加 ZIP 库支持
- ⚠️ 需要绝对路径 → 扩展路径解析逻辑
- ⚠️ 需要详细日志 → 集成或实现日志库
- ⚠️ 需要 URL 解码 → 实现 URL 解码函数

## 📚 相关文件

- `Resource.mbt` - 资源数据结构
- `ResourceResolver.mbt` - 核心扫描器
- `PathUtils.mbt` - 路径工具函数（新增）
- `ResourceResolver_test.mbt` - 测试示例
- `ResourceResolver使用说明.md` - 中文文档
