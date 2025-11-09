/// 特征系统演示 - 最终版
/// 
/// 这个文件展示 Moonbit 特征系统的正确用法

// ========== 基础类型定义 ==========

///|
/// 服务状态
pub enum ServiceStatus {
  Active
  Inactive
  Error(String) // 用于错误状态，虽然当前未使用，但保留以支持错误处理
} derive(Eq, Show)

///|
/// 服务配置
pub struct ServiceConfig {
  name : String
  timeout : Int
  retry_count : Int
} derive(Eq, Show, Default)

///|
/// 服务实例
pub struct Service {
  mut config : ServiceConfig
  mut status : ServiceStatus
} derive(Eq, Show)

// ========== 特征定义 ==========

///|
/// 可启动特征
pub trait Startable {
  start(Self) -> Unit
  is_running(Self) -> Bool
}

///|
/// 可停止特征
pub trait Stoppable {
  stop(Self) -> Unit
  is_stopped(Self) -> Bool
}

///|
/// 可配置特征
pub trait Configurable {
  get_config(Self) -> ServiceConfig
  set_config(Self, ServiceConfig) -> Unit
}

///|
/// 可监控特征
pub trait Monitorable {
  get_status(Self) -> ServiceStatus
  set_status(Self, ServiceStatus) -> Unit
  get_metrics(Self) -> String
}

// ========== 特征实现 ==========

///|
/// 实现 Startable 特征
pub impl Startable for Service with start(self) {
  self.status = Active
}

///|
pub impl Startable for Service with is_running(self) {
  match self.status {
    Active => true
    _ => false
  }
}

///|
/// 实现 Stoppable 特征
pub impl Stoppable for Service with stop(self) {
  self.status = Inactive
}

///|
pub impl Stoppable for Service with is_stopped(self) {
  match self.status {
    Inactive => true
    _ => false
  }
}

///|
/// 实现 Configurable 特征
pub impl Configurable for Service with get_config(self) {
  self.config
}

///|
pub impl Configurable for Service with set_config(self, config) {
  self.config = config
}

///|
/// 实现 Monitorable 特征
pub impl Monitorable for Service with get_status(self) {
  self.status
}

///|
pub impl Monitorable for Service with set_status(self, status) {
  self.status = status
}

///|
pub impl Monitorable for Service with get_metrics(self) {
  let name = self.config.name
  let timeout = self.config.timeout
  let status_str = match self.status {
    Active => "Active"
    Inactive => "Inactive"
    Error(msg) => "Error: " + msg
  }
  "Service: " +
  name +
  ", Status: " +
  status_str +
  ", Timeout: " +
  timeout.to_string()
}

// ========== 构造函数 ==========

///|
/// 创建服务
pub fn Service::new(name : String, timeout : Int, retry_count : Int) -> Service {
  { config: ServiceConfig::{ name, timeout, retry_count }, status: Inactive }
}

// ========== 特征对象演示 ==========

///|
/// 特征对象类型（使用结构体包装）
pub struct StartableService {
  service : Service
} derive(Eq, Show)

///|
/// 创建特征对象
pub fn StartableService::new(service : Service) -> StartableService {
  { service, }
}

///|
/// 使用特征对象
pub fn start_service(service : StartableService) -> Unit {
  service.service.start()
}

///|
/// 检查服务状态
pub fn check_service_status(service : StartableService) -> Bool {
  service.service.is_running()
}

// ========== 特征约束演示 ==========

///|
/// 使用特征约束的函数
pub fn[T : Startable] manage_startable_service(service : T) -> Unit {
  service.start()
  if service.is_running() {
    println("Service is running")
  } else {
    println("Service is not running")
  }
}

///|
/// 使用多个特征约束的函数
pub fn[T : Startable + Stoppable] manage_service_lifecycle(service : T) -> Unit {
  service.start()
  if service.is_running() {
    println("Service started successfully")
  }
  service.stop()
  if service.is_stopped() {
    println("Service stopped successfully")
  }
}

// ========== 测试 ==========

///|
test "Service 基本功能" {
  let service = Service::new("TestService", 5000, 3)

  // 测试配置
  if service.config.name != "TestService" {
    abort("name mismatch")
  }
  if service.config.timeout != 5000 {
    abort("timeout mismatch")
  }
  if service.config.retry_count != 3 {
    abort("retry count mismatch")
  }

  // 测试状态
  match service.status {
    Inactive => ()
    _ => abort("should be inactive")
  }
}

///|
test "Service 特征实现" {
  let service = Service::new("TestService", 5000, 3)

  // 测试 Startable 特征
  service.start()
  if not(service.is_running()) {
    abort("should be running")
  }

  // 测试 Stoppable 特征
  service.stop()
  if not(service.is_stopped()) {
    abort("should be stopped")
  }

  // 测试 Configurable 特征
  let config = service.get_config()
  if config.name != "TestService" {
    abort("config name mismatch")
  }

  // 测试 Monitorable 特征
  let status = service.get_status()
  match status {
    Inactive => ()
    Active => abort("should be inactive")
    Error(_) => abort("should be inactive") // 使用 Error 变体以避免警告
  }
  let metrics = service.get_metrics()
  if not(metrics.contains("TestService")) {
    abort("metrics should contain service name")
  }
}

///|
test "特征对象使用" {
  let service = Service::new("TestService", 5000, 3)
  let startable_service = StartableService::new(service)

  // 使用特征对象
  start_service(startable_service)

  // 检查状态
  if not(check_service_status(startable_service)) {
    abort("should be running")
  }
}

///|
test "特征约束使用" {
  let service = Service::new("TestService", 5000, 3)

  // 使用特征约束函数
  manage_startable_service(service)
  manage_service_lifecycle(service)

  // 验证结果
  if not(service.is_stopped()) {
    abort("should be stopped after lifecycle")
  }
}

// ========== 高级特征演示 ==========

///|
/// 可序列化特征
pub trait Serializable {
  serialize(Self) -> String
  deserialize(String) -> Self
}

///|
/// 可比较特征
pub trait Comparable {
  compare(Self, Self) -> Int
}

///|
/// 实现 Serializable 特征
pub impl Serializable for Service with serialize(self) {
  let name = self.config.name
  let timeout = self.config.timeout
  let retry = self.config.retry_count
  let status_str = match self.status {
    Active => "Active"
    Inactive => "Inactive"
    Error(msg) => "Error:" + msg
  }
  "Service{name=" +
  name +
  ",timeout=" +
  timeout.to_string() +
  ",retry=" +
  retry.to_string() +
  ",status=" +
  status_str +
  "}"
}

///|
pub impl Serializable for Service with deserialize(_data) {
  // 简化的反序列化实现
  Service::new("DeserializedService", 1000, 1)
}

///|
/// 实现 Comparable 特征
pub impl Comparable for Service with compare(self, other) {
  if self.config.timeout > other.config.timeout {
    1
  } else if self.config.timeout < other.config.timeout {
    -1
  } else {
    0
  }
}

///|
test "高级特征使用" {
  let service1 = Service::new("Service1", 5000, 3)
  let service2 = Service::new("Service2", 3000, 2)

  // 测试序列化
  let serialized = service1.serialize()
  if not(serialized.contains("Service1")) {
    abort("serialized data should contain service name")
  }

  // 测试比较
  let comparison = service1.compare(service2)
  if comparison <= 0 {
    abort("service1 should be greater than service2")
  }
  let reverse_comparison = service2.compare(service1)
  if reverse_comparison >= 0 {
    abort("service2 should be less than service1")
  }
}

// ========== 特征组合演示 ==========

///|
/// 组合特征：可启动且可停止
pub trait StartableStoppable {
  start_service(Self) -> Unit
  is_service_running(Self) -> Bool
  stop_service(Self) -> Unit
  is_service_stopped(Self) -> Bool
}

///|
/// 组合特征：可配置且可监控
pub trait ConfigurableMonitorable {
  get_service_config(Self) -> ServiceConfig
  set_service_config(Self, ServiceConfig) -> Unit
  get_service_status(Self) -> ServiceStatus
  set_service_status(Self, ServiceStatus) -> Unit
  get_service_metrics(Self) -> String
}

///|
/// 实现组合特征
pub impl StartableStoppable for Service with start_service(self) {
  self.start()
}

///|
pub impl StartableStoppable for Service with is_service_running(self) {
  self.is_running()
}

///|
pub impl StartableStoppable for Service with stop_service(self) {
  self.stop()
}

///|
pub impl StartableStoppable for Service with is_service_stopped(self) {
  self.is_stopped()
}

///|
pub impl ConfigurableMonitorable for Service with get_service_config(self) {
  self.get_config()
}

///|
pub impl ConfigurableMonitorable for Service with set_service_config(
  self,
  config,
) {
  self.set_config(config)
}

///|
pub impl ConfigurableMonitorable for Service with get_service_status(self) {
  self.get_status()
}

///|
pub impl ConfigurableMonitorable for Service with set_service_status(
  self,
  status,
) {
  self.set_status(status)
}

///|
pub impl ConfigurableMonitorable for Service with get_service_metrics(self) {
  self.get_metrics()
}

///|
test "特征组合使用" {
  let service = Service::new("TestService", 5000, 3)

  // 使用组合特征
  service.start_service()
  if not(service.is_service_running()) {
    abort("should be running")
  }
  service.stop_service()
  if not(service.is_service_stopped()) {
    abort("should be stopped")
  }

  // 测试配置和监控
  let config = service.get_service_config()
  // 使用 ServiceStatus 的所有变体以避免警告
  let status = service.get_service_status()
  match status {
    Active => ()
    Inactive => ()
    Error(_) => () // 使用 Error 变体以避免警告
  }
  let metrics = service.get_service_metrics()
  if config.name != "TestService" {
    abort("config name mismatch")
  }
  if not(metrics.contains("TestService")) {
    abort("metrics should contain service name")
  }
}

///|
/// 测试函数：演示 ServiceStatus 的所有变体（避免未使用警告）
test "ServiceStatus demo" {
  // 使用所有 ServiceStatus 变体以避免警告
  let status1 = Active
  let _ = Inactive // 使用 _ 忽略未使用的变量
  let status3 = ServiceStatus::Error("test error") // 使用完整类型名称消除歧义

  // 使用它们进行匹配以避免警告
  match status1 {
    Active => ()
    _ => abort("should be Active")
  }
  match status3 {
    Error(_) => ()
    _ => abort("should be Error")
  }
}
