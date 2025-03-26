extends RefCounted
class_name InputRecorder

## 输入记录数据结构
class InputRecord:
	## 动作名称
	var action: String
	## 是否按下
	var pressed: bool
	## 输入强度
	var strength: float
	## 记录时间
	var timestamp: float
	
	func _init(p_action: String, p_pressed: bool, p_strength: float) -> void:
		action = p_action
		pressed = p_pressed
		strength = p_strength
		timestamp = Time.get_ticks_msec() / 1000.0
	
	## 转换为字典
	func to_dict() -> Dictionary:
		return {
			"action": action,
			"pressed": pressed,
			"strength": strength,
			"timestamp": timestamp
		}

## 是否正在记录
var is_recording: bool = false
## 记录开始时间
var record_start_time: float = 0.0
## 输入记录列表
var _records: Array[InputRecord] = []
## 最大记录数量
var _max_records: int = 1000

## 开始记录
func start_recording() -> void:
	is_recording = true
	record_start_time = Time.get_ticks_msec() / 1000.0
	_records.clear()

## 停止记录
func stop_recording() -> void:
	is_recording = false

## 记录输入
## [param action] 动作名称
## [param pressed] 是否按下
## [param strength] 输入强度
func record_input(action: String, pressed: bool, strength: float = 1.0) -> void:
	if not is_recording:
		return
	
	_records.append(InputRecord.new(action, pressed, strength))
	
	# 限制记录数量
	if _records.size() > _max_records:
		_records.pop_front()

## 清除记录
func clear_records() -> void:
	_records.clear()
	record_start_time = 0.0

## 设置最大记录数量
## [param max_count] 最大记录数量
func set_max_records(max_count: int) -> void:
	_max_records = max_count
	
	# 如果当前记录数量超过新的最大值，移除多余的记录
	while _records.size() > _max_records:
		_records.pop_front()

## 获取记录数量
## [return] 记录数量
func get_record_count() -> int:
	return _records.size()

## 获取记录时长
## [return] 记录时长（秒）
func get_record_duration() -> float:
	if _records.is_empty():
		return 0.0
	return _records[-1].timestamp - record_start_time

## 获取指定时间范围内的记录
## [param start_time] 开始时间（相对于记录开始时间）
## [param end_time] 结束时间（相对于记录开始时间）
## [return] 记录列表
func get_records_in_timeframe(start_time: float, end_time: float) -> Array:
	var result = []
	for record in _records:
		var relative_time = record.timestamp - record_start_time
		if relative_time >= start_time and relative_time <= end_time:
			result.append(record.to_dict())
	return result

## 获取所有记录
## [return] 所有记录列表
func get_all_records() -> Array:
	var records = []
	for record in _records:
		records.append(record.to_dict())
	return records

## 获取最后一条记录
## [return] 最后一条记录字典，如果没有记录则返回空字典
func get_last_record() -> Dictionary:
	if _records.is_empty():
		return {}
	return _records[-1].to_dict()

## 保存记录到文件
## [param filepath] 文件路径
## [return] 是否保存成功
func save_records_to_file(filepath: String) -> bool:
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if not file:
		return false
	
	var data = {
		"start_time": record_start_time,
		"records": get_all_records()
	}
	
	file.store_string(JSON.stringify(data))
	return true

## 从文件加载记录
## [param filepath] 文件路径
## [return] 是否加载成功
func load_records_from_file(filepath: String) -> bool:
	var file = FileAccess.open(filepath, FileAccess.READ)
	if not file:
		return false
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		return false
	
	var data = json.get_data()
	if not data is Dictionary:
		return false
	
	record_start_time = data.get("start_time", 0.0)
	_records.clear()
	
	for record_data in data.get("records", []):
		var record = InputRecord.new(
			record_data.get("action", ""),
			record_data.get("pressed", false),
			record_data.get("strength", 1.0)
		)
		record.timestamp = record_data.get("timestamp", 0.0)
		_records.append(record)
	
	return true