class_name VirtualAxis
extends RefCounted

## 轴映射变更信号
signal axis_changed(axis_name: String, value: Vector2)

## 虚拟轴映射数据
var _axis_mappings: Dictionary = {}
## 轴值缓存
var _axis_values: Dictionary = {}
## 轴死区
var _deadzone: float = 0.2
## 轴灵敏度
var _sensitivity: float = 1.0

## 注册虚拟轴
## [param axis_name] 轴名称
## [param positive_action] 正向动作
## [param negative_action] 负向动作
## [param up_action] 上方动作（可选）
## [param down_action] 下方动作（可选）
func register_axis(
		axis_name: String, 
		positive_action: String, 
		negative_action: String, 
		up_action: String = "", 
		down_action: String = "") -> void:
	_axis_mappings[axis_name] = {
		"positive": positive_action,
		"negative": negative_action,
		"up": up_action,
		"down": down_action
	}
	_axis_values[axis_name] = Vector2.ZERO

## 注销虚拟轴
## [param axis_name] 轴名称
func unregister_axis(axis_name: String) -> void:
	_axis_mappings.erase(axis_name)
	_axis_values.erase(axis_name)

## 获取轴的值
## [param axis_name] 轴名称
## [return] 轴的值，范围为(-1, 1)的Vector2
func get_axis(axis_name: String) -> Vector2:
	return _axis_values.get(axis_name, Vector2.ZERO)

## 更新轴值
## [param axis_name] 轴名称
## [param input_manager] 输入管理器实例
func update_axis(axis_name: String, input_manager) -> void:
	if not _axis_mappings.has(axis_name):
		return
		
	var mapping = _axis_mappings[axis_name]
	var value = Vector2.ZERO
	
	# 水平方向
	if input_manager.is_action_pressed(mapping.positive):
		value.x += 1
	if input_manager.is_action_pressed(mapping.negative):
		value.x -= 1
	
	# 垂直方向（如果已配置）
	if mapping.up and mapping.down:
		if input_manager.is_action_pressed(mapping.up):
			value.y -= 1
		if input_manager.is_action_pressed(mapping.down):
			value.y += 1
	
	# 应用死区
	if abs(value.x) < _deadzone:
		value.x = 0
	if abs(value.y) < _deadzone:
		value.y = 0
	
	# 应用灵敏度
	value *= _sensitivity
	
	# 标准化向量
	if value.length() > 1:
		value = value.normalized()
	
	# 如果值发生变化，更新并发出信号
	if value != _axis_values[axis_name]:
		_axis_values[axis_name] = value
		axis_changed.emit(axis_name, value)

## 获取所有已注册的轴名称
## [return] 轴名称列表
func get_registered_axes() -> Array[String]:
	# 这里因为GDScript不支持协变数组，我们只能创建一个明确类型的新数组
	# 手动将每一个键添加到这个新数组
	# 尽管这样处理看起来冗长，但确实提供了更明确的意图、类型安全同时符合GDScript的类型系统要求
	# 所以让我们期盼GDScript在语法上有更好的支持
	var keys := _axis_mappings.keys()
	var string_keys: Array[String] = []
	for key in keys:
		string_keys.append(key)
	return string_keys

## 检查轴是否已注册
## [param axis_name] 轴名称
## [return] 是否已注册
func has_axis(axis_name: String) -> bool:
	return _axis_mappings.has(axis_name)

## 获取轴的映射信息
## [param axis_name] 轴名称
## [return] 轴的映射信息，如果轴不存在则返回空字典
func get_axis_mapping(axis_name: String) -> Dictionary:
	return _axis_mappings.get(axis_name, {})

## 获取所有轴映射
## [return] 所有轴映射数据
func get_axis_mappings() -> Dictionary:
	return _axis_mappings

## 设置轴映射
## [param axis_name] 轴名称
## [param mapping] 轴映射数据
func set_axis_mapping(axis_name: String, mapping: Dictionary) -> void:
	_axis_mappings[axis_name] = mapping
	_axis_values[axis_name] = Vector2.ZERO

## 获取轴灵敏度
## [return] 轴灵敏度
func get_sensitivity() -> float:
	return _sensitivity

## 设置轴灵敏度
## [param value] 灵敏度值
func set_sensitivity(value: float) -> void:
	_sensitivity = value

## 获取轴死区
## [return] 轴死区
func get_deadzone() -> float:
	return _deadzone

## 设置轴死区
## [param value] 死区值
func set_deadzone(value: float) -> void:
	_deadzone = value
