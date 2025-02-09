extends Node

## 实体逻辑基类
## 提供组件化支持和生命周期管理

## 组件添加信号
signal component_added(component_id: StringName, component: RefCounted)
## 组件移除信号
signal component_removed(component_id: StringName)

## 组件字典
var _components: Dictionary = {}

## 初始化
func _ready() -> void:
	initialize()


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
func initialize() -> void:
	for _component in _components.values():
		_initialize_component(_component)
	_initialize()

## 更新组件
func update_component(data: Dictionary = {}) -> void:
	for _component in _components.values():
		if _component is LogicComponent:
			_component.update(data)
		elif _component.has_method("_update"):
			_component._update(data)

## 添加组件
## [param component_id] 组件ID
## [param component] 组件实例
func add_component(component_id: StringName, component: RefCounted, data: Dictionary = {}) -> void:
	if not is_component(component):
		push_error("组件不是LogicComponent子类: %s" % component)
		return	
	if _components.has(component_id):
		push_warning("组件已存在: %s" % component_id)
		return
	_components[component_id] = component
	_initialize_component(component, data)
	component_added.emit(component_id, component)

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
func _initialize() -> void:
	pass

## 清理组件
func _clear_components() -> void:
	for component_id in _components.keys():
		remove_component(component_id)

## 销毁时清理组件
func _exit_tree() -> void:
	_clear_components()

## 初始化组件
func _initialize_component(component: RefCounted, data: Dictionary = {}) -> void:
	if component is LogicComponent:
		component.initialize(data)
	elif component.has_method("_initialize"):
		component._initialize(data)

## 清理组件
func _dispose_component(component: RefCounted) -> void:
	if component is LogicComponent:
		component.cleanup()
	elif component.has_method("_cleanup"):
		component._cleanup()