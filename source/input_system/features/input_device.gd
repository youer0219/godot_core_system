class_name InputDevice
extends RefCounted

## 设备类型枚举
enum Type {
    KEYBOARD_MOUSE,     ## 键盘鼠标
    GAMEPAD,            ## 游戏pad
    TOUCH,              ## 触摸
    CUSTOM              ## 自定义
}

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
var _device_state: Dictionary = {}

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

## 更新设备状态
## [param action] 动作名称
## [param pressed] 是否按下
## [param strength] 输入强度
func update_state(action: String, pressed: bool, strength: float = 1.0) -> void:
	if not _device_state.has(action):
		_device_state[action] = {"pressed": false, "strength": 0.0}
	
	_device_state[action].pressed = pressed
	_device_state[action].strength = strength
	last_input_time = Time.get_ticks_msec() / 1000.0

## 获取动作状态
## [param action] 动作名称
## [return] 动作状态
func get_action_state(action: String) -> Dictionary:
	return _device_state.get(action, {"pressed": false, "strength": 0.0})

## 检查动作是否按下
## [param action] 动作名称
## [return] 是否按下
func is_action_pressed(action: String) -> bool:
	return get_action_state(action).pressed

## 获取动作强度
## [param action] 动作名称
## [return] 动作强度
func get_action_strength(action: String) -> float:
	return get_action_state(action).strength

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

## 重置设备状态
func reset_state() -> void:
	_device_state.clear()

## 断开设备连接
func disconnect_device() -> void:
	connected = false
	reset_state()

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
		"device_state": _device_state.duplicate(true)
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
	_device_state = snapshot.get("device_state", {}).duplicate(true)