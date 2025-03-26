extends RefCounted
class_name InputVirtualAxis

## 轴值变化信号
signal axis_changed(axis_name: String, value: Vector2)

## 轴映射
var _axis_mappings: Dictionary = {}
## 轴值
var _axis_values: Dictionary = {}
## 灵敏度
var _sensitivity: float = 1.0
## 死区
var _deadzone: float = 0.1

## 轴映射数据结构
class AxisMapping:
	## 正向动作
	var positive: String
	## 负向动作
	var negative: String
	## 上方向动作
	var up: String
	## 下方向动作
	var down: String
	
	func _init(p_positive: String, p_negative: String, p_up: String = "", p_down: String = "") -> void:
		positive = p_positive
		negative = p_negative
		up = p_up
		down = p_down

## 注册虚拟轴
## [param axis_name] 轴名称
## [param positive] 正向动作
## [param negative] 负向动作
## [param up] 上方向动作（可选）
## [param down] 下方向动作（可选）
func register_axis(axis_name: String, positive: String, negative: String, up: String = "", down: String = "") -> void:
	_axis_mappings[axis_name] = AxisMapping.new(positive, negative, up, down)
	_axis_values[axis_name] = Vector2.ZERO

## 注销虚拟轴
## [param axis_name] 轴名称
func unregister_axis(axis_name: String) -> void:
	_axis_mappings.erase(axis_name)
	_axis_values.erase(axis_name)

## 获取轴值
## [param axis_name] 轴名称
## [return] 轴值
func get_axis_value(axis_name: String) -> Vector2:
	return _axis_values.get(axis_name, Vector2.ZERO)

## 更新轴值
## [param axis_name] 轴名称
## [param input_manager] 输入管理器实例
func update_axis(axis_name: String, input_manager) -> void:
	if not _axis_mappings.has(axis_name):
		return
		
	var mapping = _axis_mappings[axis_name]
	var value = Vector2.ZERO
	
	# 计算水平方向
	value.x = _calculate_axis_value(
		input_manager.is_action_pressed(mapping.positive),
		input_manager.is_action_pressed(mapping.negative)
	)
	
	# 计算垂直方向（如果已配置）
	if mapping.up and mapping.down:
		value.y = _calculate_axis_value(
			input_manager.is_action_pressed(mapping.up),
			input_manager.is_action_pressed(mapping.down)
		)
	
	# 应用死区和灵敏度
	value = _process_axis_value(value)
	
	# 只在值发生变化时更新和发送信号
	if not value.is_equal_approx(_axis_values[axis_name]):
		_axis_values[axis_name] = value
		axis_changed.emit(axis_name, value)

## 计算单个轴的值
## [param positive_pressed] 正方向是否按下
## [param negative_pressed] 负方向是否按下
## [return] 计算后的轴值
func _calculate_axis_value(positive_pressed: bool, negative_pressed: bool) -> float:
	var value = 0.0
	if positive_pressed:
		value += 1.0
	if negative_pressed:
		value -= 1.0
	return value

## 处理轴值（应用死区和灵敏度）
## [param value] 原始轴值
## [return] 处理后的轴值
func _process_axis_value(value: Vector2) -> Vector2:
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
	
	return value

## 获取所有已注册的轴名称
## [return] 轴名称列表
func get_registered_axes() -> Array:
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
	return _axis_mappings.get(axis_name, {}).to_dict()

## 获取所有轴映射
## [return] 所有轴映射数据
func get_axis_mappings() -> Dictionary:
	return _axis_mappings

## 设置轴映射
## [param axis_name] 轴名称
## [param mapping] 轴映射数据
func set_axis_mapping(axis_name: String, mapping: Dictionary) -> void:
	_axis_mappings[axis_name] = AxisMapping.new(mapping.positive, mapping.negative, mapping.up, mapping.down)
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
