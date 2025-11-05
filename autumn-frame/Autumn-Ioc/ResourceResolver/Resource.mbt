///|
/// Resource 表示找到的资源：
/// - path: 资源的完整路径（对于文件为 file: 前缀的绝对路径，对于 jar 中的资源为 jar:<jar-path>!/package/path）
/// - name: 资源相对于包根的名称（例如 `com/example/Foo.class` 或 `templates/index.html`）
pub struct Resource {
  path : String
  name : String
}

///|
pub fn Resource::new(path : String, name : String) -> Resource {
  return { path, name }
}
