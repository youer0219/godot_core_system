extends RefCounted
class_name InputDevice

## 设备类型枚举
enum Type {
    KEYBOARD_MOUSE,     ## 键盘鼠标
    GAMEPAD,            ## 游戏pad
    TOUCH,              ## 触摸
    CUSTOM              ## 自定义
}

## 设备状态变化信号
signal state_changed(action: String, state: Dictionary)

## 设备ID
var device_id: int = 0
## 设备类型
var device_type: Type = Type.KEYBOARD_MOUSE
## 设备名称
var name: String = ""
## 是否已连接
var connected: bool = false
## 最后输入时间
var last_input_time: float = 0.0
## 设备特定的输入映射
var input_mappings: Dictionary = {}
## 设备状态
var _action_states: Dictionary = {}

## 动作状态数据结构
class ActionState:
	## 是否按下
	var pressed: bool = false
	## 按下的持续时间
	var press_time: float = 0.0
	## 上次按下的时间戳
	var last_press_time: float = 0.0
	## 上次释放的时间戳
	var last_release_time: float = 0.0
	## 按下次数
	var press_count: int = 0
	## 输入强度
	var strength: float = 0.0
	
	func _init() -> void:
		reset()
	
	func reset() -> void:
		pressed = false
		press_time = 0.0
		last_press_time = 0.0
		last_release_time = 0.0
		press_count = 0
		strength = 0.0
	
	func to_dict() -> Dictionary:
		return {
			"pressed": pressed,
			"press_time": press_time,
			"last_press_time": last_press_time,
			"last_release_time": last_release_time,
			"press_count": press_count,
			"strength": strength
		}

## 初始化设备
## [param p_device_id] 设备ID
## [param p_type] 设备类型
## [param p_name] 设备名称
func _init(p_device_id: int, p_type: Type = Type.KEYBOARD_MOUSE, p_name: String = "") -> void:
	device_id = p_device_id
	device_type = p_type
	name = p_name if p_name else "Device_%d" % device_id
	connected = true
	last_input_time = Time.get_ticks_msec() / 1000.0

## 更新动作状态
## [param action] 动作名称
## [param pressed] 是否按下
## [param strength] 输入强度
func update_state(action: String, pressed: bool, strength: float = 1.0) -> void:
	if not _action_states.has(action):
		_action_states[action] = ActionState.new()
	
	var state = _action_states[action]
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if pressed != state.pressed:
		if pressed:
			state.last_press_time = current_time
			state.press_count += 1
		else:
			state.last_release_time = current_time
			state.press_time = 0.0
	
	state.pressed = pressed
	state.strength = strength
	
	if pressed:
		state.press_time = current_time - state.last_press_time
	
	state_changed.emit(action, state.to_dict())
	last_input_time = current_time

## 获取动作状态
## [param action] 动作名称
## [return] 动作状态字典
func get_action_state(action: String) -> Dictionary:
	if not _action_states.has(action):
		return {}
	return _action_states[action].to_dict()

## 获取所有动作状态
## [return] 所有动作状态字典
func get_all_states() -> Dictionary:
	var states = {}
	for action in _action_states:
		states[action] = _action_states[action].to_dict()
	return states

## 重置指定动作状态
## [param action] 动作名称
func reset_action(action: String) -> void:
	if _action_states.has(action):
		_action_states[action].reset()
		state_changed.emit(action, _action_states[action].to_dict())

## 重置所有动作状态
func reset_all() -> void:
	for action in _action_states:
		reset_action(action)

## 检查动作是否按下
## [param action] 动作名称
## [return] 是否按下
func is_pressed(action: String) -> bool:
	if not _action_states.has(action):
		return false
	return _action_states[action].pressed

## 获取动作按下时长
## [param action] 动作名称
## [return] 按下时长（秒）
func get_press_time(action: String) -> float:
	if not _action_states.has(action):
		return 0.0
	return _action_states[action].press_time

## 获取动作按下次数
## [param action] 动作名称
## [return] 按下次数
func get_press_count(action: String) -> int:
	if not _action_states.has(action):
		return 0
	return _action_states[action].press_count

## 获取动作输入强度
## [param action] 动作名称
## [return] 输入强度
func get_strength(action: String) -> float:
	if not _action_states.has(action):
		return 0.0
	return _action_states[action].strength

## 映射设备特定输入到动作
## [param device_input] 设备特定的输入标识符
## [param action] 动作名称
func map_input(device_input: String, action: String) -> void:
	input_mappings[device_input] = action

## 取消输入映射
## [param device_input] 设备特定的输入标识符
func unmap_input(device_input: String) -> void:
	input_mappings.erase(device_input)

## 清除所有输入映射
func clear_mappings() -> void:
	input_mappings.clear()

## 断开设备连接
func disconnect_device() -> void:
	connected = false
	reset_all()

## 重新连接设备
func reconnect_device() -> void:
	connected = true
	last_input_time = Time.get_ticks_msec() / 1000.0

## 获取设备状态快照
## [return] 设备状态快照
func get_state_snapshot() -> Dictionary:
	return {
		"device_id": device_id,
		"device_type": device_type,
		"name": name,
		"connected": connected,
		"last_input_time": last_input_time,
		"input_mappings": input_mappings.duplicate(),
		"action_states": get_all_states()
	}

## 从快照恢复设备状态
## [param snapshot] 设备状态快照
func restore_from_snapshot(snapshot: Dictionary) -> void:
	device_id = snapshot.get("device_id", device_id)
	device_type = snapshot.get("device_type", device_type)
	name = snapshot.get("name", name)
	connected = snapshot.get("connected", connected)
	last_input_time = snapshot.get("last_input_time", last_input_time)
	input_mappings = snapshot.get("input_mappings", {}).duplicate()
	for action in snapshot.get("action_states", {}):
		if not _action_states.has(action):
			_action_states[action] = ActionState.new()
		_action_states[action].pressed = snapshot["action_states"][action].get("pressed", false)
		_action_states[action].press_time = snapshot["action_states"][action].get("press_time", 0.0)
		_action_states[action].last_press_time = snapshot["action_states"][action].get("last_press_time", 0.0)
		_action_states[action].last_release_time = snapshot["action_states"][action].get("last_release_time", 0.0)
		_action_states[action].press_count = snapshot["action_states"][action].get("press_count", 0)
		_action_states[action].strength = snapshot["action_states"][action].get("strength", 0.0)