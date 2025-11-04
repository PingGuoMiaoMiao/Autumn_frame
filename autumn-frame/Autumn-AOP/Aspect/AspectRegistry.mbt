/// AspectRegistry - 切面注册表
/// 
/// 管理所有切面的注册和查找

// ========== 导入依赖 ==========
// 注意：Aspect 类型在同一包内定义（Aspect.mbt），可以直接使用
// Pointcut 和 Advice 通过 moon.pkg.json 导入

// ========== 切面注册表定义 ==========

/// 切面注册表
pub struct AspectRegistry {
  // 切面存储（切面名称 -> 切面）
  // 注意：Aspect 类型在同一包的 Aspect.mbt 中定义
  aspects : @hashmap.HashMap[String, Aspect]  // 同包内的类型，直接使用
  
  // 切点存储（切点名称 -> 切点）
  pointcuts : @hashmap.HashMap[String, @Pointcut.Pointcut]
  
  // 通知存储（通知名称 -> 通知）
  advices : @hashmap.HashMap[String, @Advice.Advice]
  
  // Bean 到切面的映射（Bean 名称 -> 切面名称列表）
  bean_aspects : @hashmap.HashMap[String, Array[String]]
  
  // 方法到切面的映射（Bean 名称 -> 方法名称 -> 切面名称列表）
  method_aspects : @hashmap.HashMap[String, @hashmap.HashMap[String, Array[String]]]
}

// ========== 构造函数 ==========

/// 创建切面注册表
pub fn AspectRegistry::new() -> AspectRegistry {
  {
    aspects: @hashmap.new(),
    pointcuts: @hashmap.new(),
    advices: @hashmap.new(),
    bean_aspects: @hashmap.new(),
    method_aspects: @hashmap.new()
  }
}

// ========== 切点管理 ==========

/// 注册切点
pub fn AspectRegistry::register_pointcut(
  self : AspectRegistry,
  name : String,
  pointcut : @Pointcut.Pointcut
) -> Unit {
  self.pointcuts.set(name, pointcut)
}

/// 查找切点
pub fn AspectRegistry::find_pointcut(
  self : AspectRegistry,
  name : String
) -> @Pointcut.Pointcut? {
  self.pointcuts.get(name)
}

// ========== 通知管理 ==========

/// 注册通知
pub fn AspectRegistry::register_advice(
  self : AspectRegistry,
  name : String,
  advice : @Advice.Advice
) -> Unit {
  self.advices.set(name, advice)
}

/// 查找通知
pub fn AspectRegistry::find_advice(
  self : AspectRegistry,
  name : String
) -> @Advice.Advice? {
  self.advices.get(name)
}

// ========== 切面管理 ==========

/// 注册切面
pub fn AspectRegistry::register_aspect(
  self : AspectRegistry,
  aspect : Aspect  // 同包内的类型，直接使用
) -> Unit {
  // 验证切点和通知是否存在
  match self.find_pointcut(aspect.pointcut_name) {
    Some(_) => {
      match self.find_advice(aspect.advice_name) {
        Some(_) => {
          self.aspects.set(aspect.name, aspect)
        }
        None => {
          println("⚠️  通知不存在: \{aspect.advice_name}")
        }
      }
    }
    None => {
      println("⚠️  切点不存在: \{aspect.pointcut_name}")
    }
  }
}

/// 查找切面
pub fn AspectRegistry::find_aspect(
  self : AspectRegistry,
  name : String
) -> Aspect? {
  self.aspects.get(name)
}

/// 获取所有切面
pub fn AspectRegistry::get_all_aspects(self : AspectRegistry) -> Array[Aspect] {
  let aspects_list : Array[Aspect] = []
  self.aspects.iter().each(fn(entry) {
    let (_, aspect) = entry
    aspects_list.push(aspect)
  })
  aspects_list
}

// ========== Bean 切面映射 ==========

/// 为 Bean 添加切面
pub fn AspectRegistry::add_aspect_to_bean(
  self : AspectRegistry,
  bean_name : String,
  aspect_name : String
) -> Unit {
  match self.bean_aspects.get(bean_name) {
    Some(existing) => {
      existing.push(aspect_name)
      self.bean_aspects.set(bean_name, existing)
    }
    None => {
      self.bean_aspects.set(bean_name, [aspect_name])
    }
  }
}

/// 获取 Bean 的所有切面
pub fn AspectRegistry::get_bean_aspects(
  self : AspectRegistry,
  bean_name : String
) -> Array[String] {
  match self.bean_aspects.get(bean_name) {
    Some(aspects) => aspects
    None => []
  }
}

// ========== 方法切面映射 ==========

/// 为方法添加切面
pub fn AspectRegistry::add_aspect_to_method(
  self : AspectRegistry,
  bean_name : String,
  method_name : String,
  aspect_name : String
) -> Unit {
  match self.method_aspects.get(bean_name) {
    Some(bean_methods) => {
      match bean_methods.get(method_name) {
        Some(existing) => {
          existing.push(aspect_name)
      bean_methods.set(method_name, existing)
        }
        None => {
          bean_methods.set(method_name, [aspect_name])
        }
      }
      self.method_aspects.set(bean_name, bean_methods)
    }
    None => {
      let methods = @hashmap.new()
      methods.set(method_name, [aspect_name])
      self.method_aspects.set(bean_name, methods)
    }
  }
}

/// 获取方法的所有切面
pub fn AspectRegistry::get_method_aspects(
  self : AspectRegistry,
  bean_name : String,
  method_name : String
) -> Array[String] {
  match self.method_aspects.get(bean_name) {
    Some(bean_methods) => {
      match bean_methods.get(method_name) {
        Some(aspects) => aspects
        None => []
      }
    }
    None => []
  }
}

// ========== 匹配查询 ==========

/// 辅助函数：检查数组中是否包含某个元素
fn AspectRegistry::contains_element(_self : AspectRegistry, list : Array[String], element : String) -> Bool {
  let mut found = false
  list.iter().each(fn(name) {
    if name == element {
      found = true
    }
  })
  found
}

/// 查找匹配指定 Bean 和方法的所有切面
pub fn AspectRegistry::find_matching_aspects(
  self : AspectRegistry,
  bean_name : String,
  method_name : String,
  bean_class : String
) -> Array[String] {
  let result : Array[String] = []
  
  // 1. 检查 Bean 级别的切面
  let bean_aspects = self.get_bean_aspects(bean_name)
  bean_aspects.iter().each(fn(aspect_name) {
    match self.find_aspect(aspect_name) {
      Some(aspect) => {
        match self.find_pointcut(aspect.pointcut_name) {
          Some(pointcut) => {
            if pointcut.matches(bean_name, method_name, bean_class) {
              if not(self.contains_element(result, aspect_name)) {
                result.push(aspect_name)
              }
            }
          }
          None => ()
        }
      }
      None => ()
    }
  })
  
  // 2. 检查方法级别的切面
  let method_aspects = self.get_method_aspects(bean_name, method_name)
  method_aspects.iter().each(fn(aspect_name) {
    match self.find_aspect(aspect_name) {
      Some(aspect) => {
        match self.find_pointcut(aspect.pointcut_name) {
          Some(pointcut) => {
            if pointcut.matches(bean_name, method_name, bean_class) {
              if not(self.contains_element(result, aspect_name)) {
                result.push(aspect_name)
              }
            }
          }
          None => ()
        }
      }
      None => ()
    }
  })
  
  // 3. 检查全局切面（所有方法匹配）
  self.aspects.iter().each(fn(entry) {
    let (aspect_name, aspect) = entry
    match self.find_pointcut(aspect.pointcut_name) {
      Some(pointcut) => {
        if pointcut.matches(bean_name, method_name, bean_class) {
          if not(self.contains_element(result, aspect_name)) {
            result.push(aspect_name)
          }
        }
      }
      None => ()
    }
  })
  
  result
}
