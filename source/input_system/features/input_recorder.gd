class_name InputRecorder
extends RefCounted

## 输入记录数据结构
class InputRecord:
	var timestamp: float  # 时间戳
	var action: String    # 动作名称
	var pressed: bool     # 是否按下
	var strength: float   # 输入强度
	
	func _init(p_action: String, p_pressed: bool, p_strength: float = 1.0) -> void:
		timestamp = Time.get_ticks_msec() / 1000.0
		action = p_action
		pressed = p_pressed
		strength = p_strength
	
	func to_dict() -> Dictionary:
		return {
			"timestamp": timestamp,
			"action": action,
			"pressed": pressed,
			"strength": strength
		}
	
	static func from_dict(data: Dictionary) -> InputRecord:
		var record = InputRecord.new(data.action, data.pressed, data.strength)
		record.timestamp = data.timestamp
		return record

## 记录列表
var _records: Array[InputRecord] = []
## 是否正在记录
var _is_recording: bool = false
## 记录开始时间
var _start_time: float = 0.0
## 要记录的动作列表
var _recorded_actions: Array[String] = []

## 开始记录
## [param actions] 要记录的动作列表，如果为空则记录所有动作
func start_recording(actions: Array[String] = []) -> void:
	_records.clear()
	_recorded_actions = actions
	_start_time = Time.get_ticks_msec() / 1000.0
	_is_recording = true

## 停止记录
func stop_recording() -> void:
	_is_recording = false

## 记录输入事件
## [param action] 动作名称
## [param pressed] 是否按下
## [param strength] 输入强度
func record_input(action: String, pressed: bool, strength: float = 1.0) -> void:
	if not _is_recording:
		return
	
	if not _recorded_actions.is_empty() and not action in _recorded_actions:
		return
	
	_records.append(InputRecord.new(action, pressed, strength))

## 清除记录
func clear_records() -> void:
	_records.clear()
	_start_time = 0.0

## 获取记录数据
## [return] 记录数据列表
func get_records() -> Array:
	return _records.map(func(record: InputRecord): return record.to_dict())

## 从数据加载记录
## [param data] 记录数据列表
func load_records(data: Array) -> void:
	_records.clear()
	for record_data in data:
		_records.append(InputRecord.from_dict(record_data))

## 获取记录时长
## [return] 记录时长（秒）
func get_duration() -> float:
	if _records.is_empty():
		return 0.0
	return _records[-1].timestamp - _start_time

## 是否正在记录
## [return] 是否正在记录
func is_recording() -> bool:
	return _is_recording

## 获取指定时间点的输入状态
## [param time] 时间点（相对于记录开始时间）
## [return] 输入状态字典，key为动作名称，value为{pressed: bool, strength: float}
func get_state_at_time(time: float) -> Dictionary:
	var target_time = _start_time + time
	var state = {}
	
	for record in _records:
		if record.timestamp > target_time:
			break
		
		if not state.has(record.action):
			state[record.action] = {"pressed": false, "strength": 0.0}
		
		state[record.action].pressed = record.pressed
		state[record.action].strength = record.strength
	
	return state