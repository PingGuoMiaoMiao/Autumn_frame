/// Advice - 通知定义
/// 
/// 定义在何时执行切面逻辑

// ========== 通知类型定义 ==========

///|
/// 通知类型
pub enum AdviceType {
  Before // 方法执行前
  After // 方法执行后（无论是否异常）
  Around // 环绕（最灵活，可以控制是否执行原方法）
  AfterReturning // 返回后（仅正常返回时）
  AfterThrowing // 异常后（仅异常时）
} derive(Eq, Show)

///|
/// 通知函数类型
/// 
/// 参数：
/// - context: ApplicationContext（可以获取其他 Bean）
/// - bean_name: Bean 名称
/// - method_name: 方法名称
/// - args: 方法参数数组
/// 
/// 返回值：
/// - Around 类型：如果返回 None，则继续执行原方法；如果返回 Some(value)，则跳过原方法，直接返回该值
/// - 其他类型：返回值被忽略
/// 
/// 注意：由于 Moonbit 没有泛型 Any 类型，我们使用 String? 作为返回值
/// 注意：由于循环依赖问题，这里先使用类型别名，实际使用时需要传入 ApplicationContext
pub type ApplicationContextRef = @hashmap.HashMap[String, String] // 临时类型，后续集成时替换为真正的 ApplicationContext

///|
pub type AdviceFn = (ApplicationContextRef, String, String, Array[String]) -> String?

///|
/// 通知定义
pub struct Advice {
  name : String // 通知名称
  advice_type : AdviceType // 通知类型
  advice_fn : AdviceFn // 通知函数
  order : Int // 执行顺序
}

// 注意：由于 AdviceFn 包含函数类型，Advice 无法实现 Eq 和 Show
// 如果需要显示，可以使用自定义的 to_string 方法

// ========== 构造函数 ==========

///|
/// 创建通知
pub fn Advice::new(
  name : String,
  advice_type : AdviceType,
  advice_fn : AdviceFn,
  order : Int,
) -> Advice {
  { name, advice_type, advice_fn, order }
}

///|
/// 创建前置通知
pub fn Advice::before(
  name : String,
  advice_fn : AdviceFn,
  order : Int,
) -> Advice {
  Advice::new(name, Before, advice_fn, order)
}

///|
/// 创建后置通知
pub fn Advice::after(
  name : String,
  advice_fn : AdviceFn,
  order : Int,
) -> Advice {
  Advice::new(name, After, advice_fn, order)
}

///|
/// 创建环绕通知
pub fn Advice::around(
  name : String,
  advice_fn : AdviceFn,
  order : Int,
) -> Advice {
  Advice::new(name, Around, advice_fn, order)
}

///|
/// 创建返回后通知
pub fn Advice::after_returning(
  name : String,
  advice_fn : AdviceFn,
  order : Int,
) -> Advice {
  Advice::new(name, AfterReturning, advice_fn, order)
}

///|
/// 创建异常后通知
pub fn Advice::after_throwing(
  name : String,
  advice_fn : AdviceFn,
  order : Int,
) -> Advice {
  Advice::new(name, AfterThrowing, advice_fn, order)
}

// ========== 访问方法 ==========

///|
/// 获取通知名称
pub fn Advice::get_name(self : Advice) -> String {
  self.name
}

///|
/// 获取通知类型
pub fn Advice::get_advice_type(self : Advice) -> AdviceType {
  self.advice_type
}

///|
/// 获取通知函数
pub fn Advice::get_advice_fn(self : Advice) -> AdviceFn {
  self.advice_fn
}

///|
/// 获取通知顺序
pub fn Advice::get_order(self : Advice) -> Int {
  self.order
}

///|
/// 转换为字符串（用于显示）
pub fn Advice::to_string(self : Advice) -> String {
  let type_str = match self.advice_type {
    Before => "Before"
    After => "After"
    Around => "Around"
    AfterReturning => "AfterReturning"
    AfterThrowing => "AfterThrowing"
  }
  "Advice(name=" +
  self.name +
  ", type=" +
  type_str +
  ", order=" +
  self.order.to_string() +
  ")"
}
