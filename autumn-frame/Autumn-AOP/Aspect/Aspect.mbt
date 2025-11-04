/// Aspect - 切面定义
/// 
/// 组合切点和通知，定义一个完整的切面

// ========== 导入依赖 ==========

// 注意：由于模块依赖关系，这里使用类型引用而不是直接导入
// 实际使用时需要在 Integration 模块中处理依赖关系

// ========== 切面定义 ==========

/// 切面定义
/// 
/// 组合 Pointcut（切点）和 Advice（通知），定义一个完整的切面
pub(all) struct Aspect {
  name : String           // 切面名称
  pointcut_name : String  // 切点名称（引用 Pointcut）
  advice_name : String    // 通知名称（引用 Advice）
  order : Int            // 执行顺序（越小越先执行）
}

// ========== 构造函数 ==========

/// 创建切面
pub fn Aspect::new(
  name : String,
  pointcut_name : String,
  advice_name : String,
  order : Int
) -> Aspect {
  { name, pointcut_name, advice_name, order }
}

// ========== 访问方法 ==========

/// 获取切面名称
pub fn Aspect::get_name(self : Aspect) -> String {
  self.name
}

/// 获取切点名称
pub fn Aspect::get_pointcut_name(self : Aspect) -> String {
  self.pointcut_name
}

/// 获取通知名称
pub fn Aspect::get_advice_name(self : Aspect) -> String {
  self.advice_name
}

/// 获取切面顺序
pub fn Aspect::get_order(self : Aspect) -> Int {
  self.order
}

/// 转换为字符串（用于显示）
pub fn Aspect::to_string(self : Aspect) -> String {
  "Aspect(name=" + self.name + 
  ", pointcut=" + self.pointcut_name + 
  ", advice=" + self.advice_name + 
  ", order=" + self.order.to_string() + ")"
}

