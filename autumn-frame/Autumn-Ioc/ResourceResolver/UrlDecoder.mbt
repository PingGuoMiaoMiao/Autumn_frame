/// URL 解码工具
/// 对应 Java 的 URLDecoder.decode()

///|
/// URL 解码：将 %XX 形式的编码转换回原字符
/// 例如：%20 -> 空格, %2F -> /
pub fn url_decode(s : String) -> String {
  let mut result = ""
  let mut i = 0
  let len = s.length()
  while i < len {
    let c = s[i].unsafe_to_char()
    if c == '%' && i + 2 < len {
      // 解析十六进制编码
      let hex = s[i + 1:i + 3].to_string() catch { _ => "" }
      match parse_hex_byte(hex) {
        Some(byte) => {
          result = result + byte.to_string()
          i = i + 3
        }
        None => {
          result = result + c.to_string()
          i = i + 1
        }
      }
    } else if c == '+' {
      // 空格的另一种编码形式
      result = result + " "
      i = i + 1
    } else {
      result = result + c.to_string()
      i = i + 1
    }
  }
  result
}

///|
/// 解析十六进制字节
fn parse_hex_byte(hex : String) -> Char? {
  if hex.length() != 2 {
    return None
  }
  let c1_str = hex[0:1].to_string() catch { _ => return None }
  let c2_str = hex[1:2].to_string() catch { _ => return None }
  if c1_str.length() == 0 || c2_str.length() == 0 {
    return None
  }
  let c1 = c1_str[0].unsafe_to_char()
  let c2 = c2_str[0].unsafe_to_char()
  let high = hex_char_to_int(c1)
  let low = hex_char_to_int(c2)
  match (high, low) {
    (Some(h), Some(l)) => {
      let value = h * 16 + l
      Some(value.unsafe_to_char())
    }
    _ => None
  }
}

///|
/// 十六进制字符转整数
fn hex_char_to_int(c : Char) -> Int? {
  if c >= '0' && c <= '9' {
    Some(c.to_int() - '0'.to_int())
  } else if c >= 'A' && c <= 'F' {
    Some(c.to_int() - 'A'.to_int() + 10)
  } else if c >= 'a' && c <= 'f' {
    Some(c.to_int() - 'a'.to_int() + 10)
  } else {
    None
  }
}

///|
/// URL 编码：将特殊字符编码为 %XX 形式
pub fn url_encode(s : String) -> String {
  let mut result = ""
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].unsafe_to_char()

    // 安全字符：a-z, A-Z, 0-9, -, _, ., ~
    if (c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      c == '-' ||
      c == '_' ||
      c == '.' ||
      c == '~' {
      result = result + c.to_string()
    } else if c == ' ' {
      result = result + "+"
    } else {
      // 编码为 %XX
      result = result + "%" + int_to_hex(c.to_int())
    }
  }
  result
}

///|
/// 整数转十六进制字符串（2位）
fn int_to_hex(n : Int) -> String {
  let high = n / 16
  let low = n % 16
  int_to_hex_char(high).to_string() + int_to_hex_char(low).to_string()
}

///|
/// 整数转十六进制字符
fn int_to_hex_char(n : Int) -> Char {
  if n < 10 {
    ('0'.to_int() + n).unsafe_to_char()
  } else {
    ('A'.to_int() + (n - 10)).unsafe_to_char()
  }
}

// ========== 测试 ==========

///|
test "url_decode ASCII" {
  if url_decode("hello%20world") != "hello world" {
    abort("url_decode ASCII failed")
  }
  if url_decode("test%2Bvalue") != "test+value" {
    abort("url_decode + failed")
  }
  if url_decode("100%25") != "100%" {
    abort("url_decode % failed")
  }
}

///|
test "url_decode 空格" {
  if url_decode("hello+world") != "hello world" {
    abort("url_decode + to space failed")
  }
  if url_decode("a+b+c") != "a b c" {
    abort("url_decode multiple + failed")
  }
}

///|
test "url_decode 路径" {
  if url_decode("path%2Fto%2Ffile") != "path/to/file" {
    abort("url_decode path failed")
  }
}

///|
test "url_encode ASCII" {
  if url_encode("hello world") != "hello+world" {
    abort("url_encode space failed")
  }
  if url_encode("test/path") != "test%2Fpath" {
    abort("url_encode slash failed")
  }
}

///|
test "url_decode 往返" {
  let original = "hello world"
  let encoded = url_encode(original)
  let decoded = url_decode(encoded)
  if decoded != original {
    abort("url_decode roundtrip failed")
  }
}
