/// Pointcut - 切点定义
/// 
/// 定义哪些方法需要被拦截

// ========== 切点类型定义 ==========

/// 切点匹配模式
pub enum PointcutPattern {
  AllMethods                    // 所有方法
  MethodName(String)           // 特定方法名（如：getUser）
  MethodPattern(String)        // 方法名模式（如：get*）
  ClassPattern(String)         // 类名模式（如：com.example.*）
  Annotation(String)           // 注解匹配（如：@Transactional）
  Expression(String)           // 表达式（如：execution(* com.example.*.*(..))）
} derive(Eq, Show)

/// 切点定义
/// 
/// 用于指定哪些方法需要被拦截
pub struct Pointcut {
  name : String                // 切点名称
  pattern : PointcutPattern    // 匹配模式
  order : Int                 // 执行顺序（越小越先执行）
} derive(Eq, Show)

// ========== 构造函数 ==========

/// 创建切点
pub fn Pointcut::new(name : String, pattern : PointcutPattern, order : Int) -> Pointcut {
  { name, pattern, order }
}

/// 创建"所有方法"切点
pub fn Pointcut::all_methods(name : String, order : Int) -> Pointcut {
  Pointcut::new(name, AllMethods, order)
}

/// 创建"方法名"切点
pub fn Pointcut::method_name(name : String, method_name : String, order : Int) -> Pointcut {
  Pointcut::new(name, MethodName(method_name), order)
}

/// 创建"方法模式"切点
pub fn Pointcut::method_pattern(name : String, pattern : String, order : Int) -> Pointcut {
  Pointcut::new(name, MethodPattern(pattern), order)
}

/// 创建"类模式"切点
pub fn Pointcut::class_pattern(name : String, pattern : String, order : Int) -> Pointcut {
  Pointcut::new(name, ClassPattern(pattern), order)
}

/// 创建"注解"切点
pub fn Pointcut::annotation(name : String, annotation : String, order : Int) -> Pointcut {
  Pointcut::new(name, Annotation(annotation), order)
}

// ========== 匹配方法 ==========

/// 检查方法是否匹配切点
pub fn Pointcut::matches(self : Pointcut, _bean_name : String, method_name : String, bean_class : String) -> Bool {
  match self.pattern {
    AllMethods => true
    MethodName(name) => method_name == name
    MethodPattern(pattern) => {
      // 简化实现：检查前缀或后缀
      if pattern.has_suffix("*") {
        try {
          let prefix = pattern[0:pattern.length() - 1].to_string()
          method_name.has_prefix(prefix)
        } catch {
          _ => false
        }
      } else if pattern.has_prefix("*") {
        try {
          let suffix = pattern[1:].to_string()
          method_name.has_suffix(suffix)
        } catch {
          _ => false
        }
      } else {
        method_name == pattern
      }
    }
    ClassPattern(pattern) => {
      // 简化实现：检查类名前缀
      if pattern.has_suffix("*") {
        try {
          let prefix = pattern[0:pattern.length() - 1].to_string()
          bean_class.has_prefix(prefix)
        } catch {
          _ => false
        }
      } else {
        bean_class == pattern
      }
    }
    Annotation(_annotation) => {
      // 注解匹配：实际应该从方法或类上读取注解
      // 这里简化实现，假设有注解注册表
      false  // 待实现
    }
    Expression(_expr) => {
      // 表达式匹配：实际应该解析 execution 表达式
      // 这里简化实现
      false  // 待实现
    }
  }
}

/// 获取切点名称
pub fn Pointcut::get_name(self : Pointcut) -> String {
  self.name
}

/// 获取切点顺序
pub fn Pointcut::get_order(self : Pointcut) -> Int {
  self.order
}

/// 获取切点模式
pub fn Pointcut::get_pattern(self : Pointcut) -> PointcutPattern {
  self.pattern
}

