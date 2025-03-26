class_name VirtualAxis
extends RefCounted

## 虚拟轴映射数据
var _axis_mappings: Dictionary = {}

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

## 注销虚拟轴
## [param axis_name] 轴名称
func unregister_axis(axis_name: String) -> void:
	_axis_mappings.erase(axis_name)

## 获取轴的值
## [param axis_name] 轴名称
## [return] 轴的值，范围为(-1, 1)的Vector2
func get_axis(axis_name: String) -> Vector2:
	if not _axis_mappings.has(axis_name):
		return Vector2.ZERO
		
	var mapping = _axis_mappings[axis_name]
	var value = Vector2.ZERO
	
	# 水平方向
	if Input.is_action_pressed(mapping.positive):
		value.x += 1
	if Input.is_action_pressed(mapping.negative):
		value.x -= 1
	
	# 垂直方向（如果已配置）
	if mapping.up and mapping.down:
		if Input.is_action_pressed(mapping.up):
			value.y -= 1
		if Input.is_action_pressed(mapping.down):
			value.y += 1
	
	return value.normalized() if value.length() > 1 else value

## 获取所有已注册的轴名称
## [return] 轴名称列表
func get_registered_axes() -> Array[String]:
	return _axis_mappings.keys()

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