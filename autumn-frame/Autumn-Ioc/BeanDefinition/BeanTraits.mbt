/// Bean 相关特征定义
/// 
/// 这个文件定义了 Bean 相关的特征，用于抽象 Bean 的生命周期管理

/// Bean 元数据特征 - 提供 Bean 的基本信息
pub trait BeanMetadata {
  get_name(Self) -> String
  get_bean_class(Self) -> String
  get_order(Self) -> Int
  is_primary(Self) -> Bool
}

/// Bean 实例管理特征 - 管理 Bean 实例的创建和销毁
pub trait BeanInstanceManager {
  get_instance(Self) -> BeanInstance
  set_instance(Self, String) -> Unit
  has_instance(Self) -> Bool
}

/// Bean 创建特征 - 定义 Bean 的创建方式
pub trait BeanCreation {
  is_constructor_creation(Self) -> Bool
  is_factory_creation(Self) -> Bool
  get_factory_bean_name(Self) -> String?
  get_factory_method_name(Self) -> String?
}

/// Bean 生命周期特征 - 管理 Bean 的初始化和销毁
pub trait BeanLifecycle {
  get_init_method_name(Self) -> String?
  get_destroy_method_name(Self) -> String?
  can_initialize(Self) -> Bool
  can_destroy(Self) -> Bool
}

/// Bean 工厂特征 - 用于创建 Bean 实例
pub trait BeanFactory {
  create_bean(Self, BeanDefinition) -> BeanInstance
  can_create_bean(Self, BeanDefinition) -> Bool
}

/// Bean 创建器特征 - 具体的 Bean 创建逻辑
pub trait BeanCreator {
  create_by_constructor(Self, BeanDefinition) -> BeanInstance
  create_by_factory(Self, BeanDefinition) -> BeanInstance
}

/// Bean 验证特征 - 验证 Bean 定义的有效性
pub trait BeanValidator {
  validate_definition(Self, BeanDefinition) -> Bool
  get_validation_errors(Self, BeanDefinition) -> Array[String]
}

/// Bean 排序特征 - 用于 Bean 的排序和比较
pub trait BeanOrdering {
  get_priority(Self) -> Int
  compare_priority(Self, Self) -> Int
}

/// Bean 依赖特征 - 管理 Bean 之间的依赖关系
pub trait BeanDependency {
  get_dependencies(Self) -> Array[String]
  add_dependency(Self, String) -> Unit
  remove_dependency(Self, String) -> Unit
  has_dependency(Self, String) -> Bool
}

/// Bean 作用域枚举
pub enum BeanScope {
  Singleton
  Prototype
  Request
  Session
} derive(Eq, Show)

/// Bean 作用域特征 - 管理 Bean 的作用域
pub trait BeanScopeManager {
  get_scope(Self) -> BeanScope
  is_singleton(Self) -> Bool
  is_prototype(Self) -> Bool
}

/// Bean 配置特征 - 管理 Bean 的配置信息
pub trait BeanConfiguration {
  get_config_properties(Self) -> Array[(String, String)]
  set_config_property(Self, String, String) -> Unit
  get_config_property(Self, String) -> String?
}

/// Bean 事件特征 - 支持 Bean 的事件通知
pub trait BeanEventListener {
  on_bean_created(Self, String) -> Unit
  on_bean_destroyed(Self, String) -> Unit
  on_bean_initialized(Self, String) -> Unit
}

/// Bean 监控特征 - 监控 Bean 的状态
pub trait BeanMonitor {
  get_bean_status(Self, String) -> BeanStatus
  get_all_bean_status(Self) -> Array[(String, BeanStatus)]
  is_bean_healthy(Self, String) -> Bool
}

/// Bean 状态枚举
pub enum BeanStatus {
  NotCreated
  Creating
  Created
  Initializing
  Initialized
  Destroying
  Destroyed
  Error(String)
} derive(Eq, Show)

/// Bean 序列化特征 - 支持 Bean 的序列化
pub trait BeanSerializable {
  serialize_bean(Self, BeanDefinition) -> String
  deserialize_bean(Self, String) -> BeanDefinition?
}

/// Bean 缓存特征 - 支持 Bean 的缓存
pub trait BeanCache {
  cache_bean(Self, String, BeanDefinition) -> Unit
  get_cached_bean(Self, String) -> BeanDefinition?
  clear_cache(Self) -> Unit
  is_cached(Self, String) -> Bool
}
