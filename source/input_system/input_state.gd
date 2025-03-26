class_name InputState
extends RefCounted

## 输入状态变化信号
signal state_changed(action: String, state: Dictionary)

## 动作状态
var _action_states: Dictionary = {}
## 上一帧的动作状态
var _previous_states: Dictionary = {}

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
	
	func to_dict() -> Dictionary:
		return {
			"pressed": pressed,
			"press_time": press_time,
			"last_press_time": last_press_time,
			"last_release_time": last_release_time,
			"press_count": press_count,
			"strength": strength
		}
	
	## 创建状态副本
	func duplicate() -> ActionState:
		var copy = ActionState.new()
		copy.pressed = pressed
		copy.press_time = press_time
		copy.last_press_time = last_press_time
		copy.last_release_time = last_release_time
		copy.press_count = press_count
		copy.strength = strength
		return copy

## 初始化动作状态
## [param action] 动作名称
func init_action(action: String) -> void:
	if not _action_states.has(action):
		_action_states[action] = ActionState.new()
		_previous_states[action] = ActionState.new()

## 更新动作状态
## [param action] 动作名称
## [param pressed] 是否按下
## [param strength] 输入强度
func update_action(action: String, pressed: bool, strength: float = 1.0) -> void:
	if not _action_states.has(action):
		init_action(action)
	
	# 保存上一帧的状态
	_previous_states[action] = _action_states[action].duplicate()
	
	var state = _action_states[action] as ActionState
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

## 获取动作状态
## [param action] 动作名称
## [return] 动作状态
func get_action_state(action: String) -> Dictionary:
	if not _action_states.has(action):
		return {}
	return _action_states[action].to_dict()

## 检查动作是否按下
## [param action] 动作名称
## [return] 是否按下
func is_pressed(action: String) -> bool:
	if not _action_states.has(action):
		return false
	return _action_states[action].pressed

## 检查动作是否刚刚被按下
## [param action] 动作名称
## [return] 是否刚刚按下
func is_just_pressed(action: String) -> bool:
	if not _action_states.has(action) or not _previous_states.has(action):
		return false
	return _action_states[action].pressed and not _previous_states[action].pressed

## 检查动作是否刚刚被释放
## [param action] 动作名称
## [return] 是否刚刚释放
func is_just_released(action: String) -> bool:
	if not _action_states.has(action) or not _previous_states.has(action):
		return false
	return not _action_states[action].pressed and _previous_states[action].pressed

## 获取动作按下时长
## [param action] 动作名称
## [return] 按下时长
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

## 重置动作状态
## [param action] 动作名称
func reset_action(action: String) -> void:
	if _action_states.has(action):
		_action_states[action] = ActionState.new()
		_previous_states[action] = ActionState.new()
		state_changed.emit(action, _action_states[action].to_dict())

## 重置所有动作状态
func reset_all() -> void:
	for action in _action_states.keys():
		reset_action(action)

## 获取所有动作状态
## [return] 所有动作状态
func get_all_states() -> Dictionary:
	var states = {}
	for action in _action_states:
		states[action] = _action_states[action].to_dict()
	return states

## 创建状态快照
## [return] 状态快照
func create_snapshot() -> Dictionary:
	var snapshot = {}
	for action in _action_states:
		snapshot[action] = {
			"current": _action_states[action].to_dict(),
			"previous": _previous_states[action].to_dict()
		}
	return snapshot

## 从快照恢复状态
## [param snapshot] 状态快照
func restore_from_snapshot(snapshot: Dictionary) -> void:
	for action in snapshot:
		if not _action_states.has(action):
			_action_states[action] = ActionState.new()
			_previous_states[action] = ActionState.new()
		
		var current_data = snapshot[action].get("current", {})
		var previous_data = snapshot[action].get("previous", {})
		
		_restore_state(_action_states[action], current_data)
		_restore_state(_previous_states[action], previous_data)
		
		state_changed.emit(action, _action_states[action].to_dict())

## 从数据恢复单个状态
## [param state] 要恢复的状态对象
## [param data] 状态数据
func _restore_state(state: ActionState, data: Dictionary) -> void:
	state.pressed = data.get("pressed", false)
	state.press_time = data.get("press_time", 0.0)
	state.last_press_time = data.get("last_press_time", 0.0)
	state.last_release_time = data.get("last_release_time", 0.0)
	state.press_count = data.get("press_count", 0)
	state.strength = data.get("strength", 0.0)