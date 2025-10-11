# ClassLoader 替代方案

## 问题分析

Java 的 `ClassLoader.getResources()` 的核心功能：
1. **自动发现资源位置** - 从多个源（文件系统、JAR、网络）
2. **类路径扫描** - 遍历 classpath 中的所有路径
3. **返回多个 URL** - 同一资源可能在多处

## Moonbit 的限制

- ❌ 没有运行时类加载机制
- ❌ 没有动态类路径概念
- ❌ 编译到 WebAssembly，资源在编译时确定

---

## 解决方案 1：配置文件方式 ⭐ 推荐

### 原理
在项目中维护一个资源清单文件，列出所有需要扫描的路径。

### 实现

```moonbit
// ResourceConfig.mbt

/// 资源配置：定义资源扫描路径
pub struct ResourceConfig {
  paths : @list.List[String]  // 资源路径列表
}

/// 从配置创建 ResourceResolver
pub fn ResourceResolver::from_config(
  base_package : String,
  config : ResourceConfig
) -> ResourceResolver {
  let mut resolver = ResourceResolver::new(base_package)
  resolver.config = Some(config)
  resolver
}

/// 扫描多个路径
pub fn [T] ResourceResolver::scan_multiple_paths(
  self : ResourceResolver,
  paths : @list.List[String],
  mapper : (Resource) -> T?
) -> @list.List[T] {
  let mut collector : @list.List[T] = @list.empty()
  
  // 遍历所有路径
  let _ = paths.map(fn(path) {
    if @fs.path_exists(path) {
      try {
        if @fs.is_dir(path) {
          collector = scan_dir(path, path, collector, mapper, self.debug)
        }
      } catch {
        _ => ()
      }
    }
  })
  
  collector.rev()
}
```

### 使用示例

```moonbit
// 定义资源路径
let config = {
  paths: @list.List::from_array([
    "./src/main/resources",
    "./lib/resources",
    "./config"
  ])
}

let resolver = ResourceResolver::from_config("com.example", config)

let resources = resolver.scan_multiple_paths(
  config.paths,
  fn(res) { Some(res) }
)
```

---

## 解决方案 2：环境变量方式

### 原理
通过环境变量传递资源路径，类似 Java 的 classpath。

```moonbit
/// 从环境变量读取资源路径
pub fn get_resource_paths() -> @list.List[String] {
  // 模拟读取环境变量 RESOURCE_PATH
  // 实际实现需要 Moonbit 的环境变量 API
  let env_paths = ".:./resources:./lib/resources"
  
  // 分割路径
  split_paths(env_paths, ':')
}

fn split_paths(s : String, sep : Char) -> @list.List[String] {
  // 简单的字符串分割实现
  let mut result = @list.empty()
  let mut current = ""
  
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].unsafe_to_char()
    if c == sep {
      if current.length() > 0 {
        result = @list.cons(current, result)
        current = ""
      }
    } else {
      current = current + c.to_string()
    }
  }
  
  if current.length() > 0 {
    result = @list.cons(current, result)
  }
  
  result.rev()
}
```

---

## 解决方案 3：编译时生成 ⭐⭐ 最强大

### 原理
在编译时扫描文件系统，生成资源清单代码。

### 实现思路

```bash
# 编译前脚本
#!/bin/bash
# generate_resources.sh

echo "/// 自动生成的资源清单" > ResourceManifest.mbt
echo "pub fn get_all_resources() -> @list.List[String] {" >> ResourceManifest.mbt
echo "  @list.List::from_array([" >> ResourceManifest.mbt

# 扫描资源目录
find ./resources -type f | while read file; do
  echo "    \"$file\"," >> ResourceManifest.mbt
done

echo "  ])" >> ResourceManifest.mbt
echo "}" >> ResourceManifest.mbt
```

生成的代码：
```moonbit
/// 自动生成的资源清单
pub fn get_all_resources() -> @list.List[String] {
  @list.List::from_array([
    "./resources/config.json",
    "./resources/data.xml",
    "./resources/templates/index.html",
  ])
}
```

---

## 解决方案 4：嵌入资源 🎯 最优雅

### 原理
将资源文件直接嵌入到编译后的 WASM 中。

```moonbit
/// 嵌入的资源数据
pub struct EmbeddedResource {
  path : String
  name : String
  content : String  // 资源内容
}

/// 资源注册表（编译时生成）
let embedded_resources : @list.List[EmbeddedResource] = @list.List::from_array([
  { path: "config/app.json", name: "app.json", content: "{...}" },
  { path: "templates/main.html", name: "main.html", content: "<html>..." },
])

/// 从嵌入资源扫描
pub fn [T] ResourceResolver::scan_embedded(
  mapper : (EmbeddedResource) -> T?
) -> @list.List[T] {
  let mut collector = @list.empty()
  
  let _ = embedded_resources.map(fn(res) {
    match mapper(res) {
      Some(v) => collector = @list.cons(v, collector)
      None => ()
    }
  })
  
  collector.rev()
}
```

---

## 解决方案 5：混合方式 🌟 实用主义

### 原理
结合多种方案的优点：
1. 开发时：文件系统扫描（灵活）
2. 生产时：嵌入资源（性能好）

```moonbit
/// 资源来源
enum ResourceSource {
  FileSystem(String)         // 文件系统路径
  Embedded(EmbeddedResource) // 嵌入的资源
  Remote(String)             // 远程 URL（如果支持网络）
}

/// 增强的 ResourceResolver
pub struct EnhancedResourceResolver {
  base_package : String
  sources : @list.List[ResourceSource]
  debug : Bool
}

/// 扫描所有来源
pub fn [T] EnhancedResourceResolver::scan_all(
  self : EnhancedResourceResolver,
  mapper : (Resource) -> T?
) -> @list.List[T] {
  let mut collector = @list.empty()
  
  let _ = self.sources.map(fn(source) {
    match source {
      FileSystem(path) => {
        // 扫描文件系统
        if @fs.path_exists(path) {
          try {
            collector = scan_dir(path, path, collector, mapper, self.debug)
          } catch {
            _ => ()
          }
        }
      }
      Embedded(res) => {
        // 处理嵌入资源
        let resource = Resource::new("embedded:" + res.path, res.name)
        match mapper(resource) {
          Some(v) => collector = @list.cons(v, collector)
          None => ()
        }
      }
      Remote(_url) => {
        // 如果支持，可以从网络加载
        // 暂时跳过
      }
    }
  })
  
  collector.rev()
}
```

---

## 推荐方案对比

| 方案 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **配置文件** | 简单、灵活 | 需要手动维护 | 小型项目 |
| **环境变量** | 类似 classpath | 依赖环境 | 多环境部署 |
| **编译时生成** | 自动化、准确 | 需要构建脚本 | 大型项目 |
| **嵌入资源** | 性能最好 | 编译包大 | 生产环境 |
| **混合方式** | 灵活 + 性能 | 复杂 | 企业项目 |

---

## 我的建议 ⭐

### 短期方案（立即可用）
使用**配置文件方式**，在代码中显式指定扫描路径：

```moonbit
let resolver = ResourceResolver::new("com.example")

// 方法 1：扫描单个路径（当前实现）
let results1 = resolver.scan(mapper)

// 方法 2：扫描多个路径（扩展）
let paths = [@list.Cons("./resources", @list.Cons("./config", @list.Nil))]
let results2 = resolver.scan_multiple_paths(paths, mapper)
```

### 长期方案（最佳实践）
实现**混合方式**：
- 开发环境：使用文件系统扫描（方便调试）
- 生产环境：使用嵌入资源（性能优化）

```moonbit
let resolver = if is_production() {
  // 生产：使用嵌入资源
  EnhancedResourceResolver::with_embedded()
} else {
  // 开发：扫描文件系统
  EnhancedResourceResolver::with_filesystem("./resources")
}
```

---

## 结论

**ClassLoader 的本质是资源定位机制**，在 Moonbit 中有多种替代方案：

1. ✅ **URL 解码** - 已实现（UrlDecoder.mbt）
2. ✅ **文件系统扫描** - 已实现（ResourceResolver.mbt）
3. ⚠️ **多路径支持** - 需要扩展（可以立即添加）
4. 🔮 **嵌入资源** - 需要工具链支持（未来方向）

**下一步建议**：
我可以立即为你实现"配置文件方式"或"多路径扫描"功能，这样就能完全替代 Java 的 ClassLoader 机制了！

你想让我实现哪个方案？
