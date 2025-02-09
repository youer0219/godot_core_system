extends Node
class_name EntityLogic

## 实体逻辑基类
## 提供组件化支持和生命周期管理

## 组件添加信号
signal component_added(component_id: StringName, component: RefCounted)
## 组件移除信号
signal component_removed(component_id: StringName)

## 组件字典
var _components: Dictionary = {}

## 判断是否为组件
func is_component(ref: RefCounted) -> bool:
	if ref == null:
		return false
	if ref is LogicComponent:
		return true
	# 如果ref存在component_id属性则是组件
	if "component_id" in ref:
		return true
	return false

## 初始化
func initialize(data: Dictionary = {}) -> void:
	for _component in _components.values():
		_initialize_component(_component)
	_initialize(data)

## 更新组件
func update_component(component_id: StringName, data: Dictionary = {}) -> void:
	var component = _components.get(component_id)
	if component == null:
		push_warning("组件不存在: %s" % component_id)
		return
	_update_component(component, data)

## 添加组件
## [param component_id] 组件ID
## [param component] 组件实例
func add_component(component_id: StringName, component: RefCounted) -> RefCounted:
	if not is_component(component):
		push_error("组件不是LogicComponent子类: %s" % component)
		return	
	if _components.has(component_id):
		push_warning("组件已存在: %s" % component_id)
		return
	_components[component_id] = component
	_initialize_component(component)
	component_added.emit(component_id, component)
	return component

## 移除组件
## [param component_id] 组件ID
func remove_component(component_id: StringName) -> void:
	if not _components.has(component_id):
		push_warning("组件不存在: %s" % component_id)
		return
	var component : RefCounted = _components[component_id]
	_components.erase(component_id)
	_dispose_component(component)
	component_removed.emit(component_id)

## 获取组件
## [param component_id] 组件ID
## [return] 组件实例
func get_component(component_id: StringName) -> RefCounted:
	return _components.get(component_id)

## 获取所有组件
## [return] 组件字典
func get_components() -> Dictionary:
	return _components

## 初始化
func _initialize(data: Dictionary = {}) -> void:
	pass

## 清理组件
func _clear_components() -> void:
	for component_id in _components.keys():
		remove_component(component_id)

## 销毁时清理组件
func _exit_tree() -> void:
	_clear_components()

## 初始化组件
func _initialize_component(component: RefCounted) -> void:
	if "owner" in component:
		component.owner = self
	if component is LogicComponent:
		component.initialize()
	elif component.has_method("_initialize"):
		component._initialize()

## 清理组件
func _dispose_component(component: RefCounted) -> void:
	if component is LogicComponent:
		component.cleanup()
	elif component.has_method("_cleanup"):
		component._cleanup()
	if "owner" in component:
		component.owner = null

## 更新组件数据
func _update_component(component: RefCounted, data: Dictionary) -> void:
	if component is LogicComponent:
		component.update_data(data)
	elif component.has_method("_on_data_updated"):
		component._on_data_updated(data)
