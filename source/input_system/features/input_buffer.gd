extends RefCounted
class_name InputBuffer

## 缓冲时间（秒）
var _buffer_duration: float = 0.2
## 缓冲数据
var _buffers: Dictionary = {}

## 缓冲数据结构
class BufferData:
	## 时间戳（秒）
	var timestamp: float
	## 输入强度
	var strength: float
	## 是否已消耗
	var consumed: bool
	
	func _init(strength_value: float = 1.0) -> void:
		timestamp = Time.get_ticks_msec() / 1000.0
		strength = strength_value
		consumed = false

## 设置缓冲时间
## [param duration] 缓冲时间（秒）
func set_buffer_duration(duration: float) -> void:
	_buffer_duration = duration

## 获取缓冲时间
## [return] 缓冲时间（秒）
func get_buffer_duration() -> float:
	return _buffer_duration

## 添加输入缓冲
## [param action_name] 动作名称
## [param strength] 输入强度
func add_buffer(action_name: String, strength: float = 1.0) -> void:
	if not _buffers.has(action_name):
		_buffers[action_name] = []
	_buffers[action_name].append(BufferData.new(strength))

## 检查是否有可用的输入缓冲
## [param action_name] 动作名称
## [param consume] 是否消耗缓冲
## [return] 如果有可用的缓冲返回true
func has_buffer(action_name: String, consume: bool = true) -> bool:
	if not _buffers.has(action_name):
		return false
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var buffer_list = _buffers[action_name]
	
	for buffer in buffer_list:
		if buffer.consumed:
			continue
			
		if current_time - buffer.timestamp <= _buffer_duration:
			if consume:
				buffer.consumed = true
			return true
	
	return false

## 获取输入缓冲的强度
## [param action_name] 动作名称
## [return] 输入强度，如果没有可用缓冲返回0
func get_buffer_strength(action_name: String) -> float:
	if not _buffers.has(action_name):
		return 0.0
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var buffer_list = _buffers[action_name]
	
	for buffer in buffer_list:
		if buffer.consumed:
			continue
			
		if current_time - buffer.timestamp <= _buffer_duration:
			return buffer.strength
	
	return 0.0

## 清理过期的输入缓冲
func clean_expired_buffers() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	for action in _buffers.keys():
		var buffer_list = _buffers[action]
		var i = buffer_list.size() - 1
		
		while i >= 0:
			var buffer = buffer_list[i]
			if buffer.consumed or current_time - buffer.timestamp > _buffer_duration:
				buffer_list.remove_at(i)
			i -= 1
		
		if buffer_list.is_empty():
			_buffers.erase(action)

## 清除指定动作的输入缓冲
## [param action_name] 动作名称
func clear_action_buffer(action_name: String) -> void:
	if _buffers.has(action_name):
		_buffers.erase(action_name)

## 清除所有输入缓冲
func clear_buffers() -> void:
	_buffers.clear()

## 获取所有缓冲数据
## [return] 缓冲数据字典
func get_all_buffers() -> Dictionary:
	var result = {}
	var current_time = Time.get_ticks_msec() / 1000.0
	
	for action in _buffers:
		var buffer_list = []
		for buffer in _buffers[action]:
			if current_time - buffer.timestamp <= _buffer_duration:
				buffer_list.append({
					"timestamp": buffer.timestamp,
					"strength": buffer.strength,
					"consumed": buffer.consumed
				})
		if not buffer_list.is_empty():
			result[action] = buffer_list
	
	return result