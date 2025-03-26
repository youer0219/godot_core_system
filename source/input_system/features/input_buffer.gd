class_name InputBuffer
extends RefCounted

## 默认的输入缓冲时间（秒）
const DEFAULT_BUFFER_TIME : float = 0.2

## 输入缓冲数据
var _buffers: Dictionary = {}

## 添加输入缓冲
## [param action_name] 动作名称
## [param strength] 输入强度
func add_buffer(action_name: String, strength: float = 1.0) -> void:
	if not _buffers.has(action_name):
		_buffers[action_name] = []
	
	_buffers[action_name].append({
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"strength": strength,
		"consumed": false
	})

## 检查是否有可用的输入缓冲
## [param action_name] 动作名称
## [param consume] 是否消耗缓冲
## [return] 如果有可用的输入缓冲返回true
func has_buffer(action_name: String, consume: bool = true) -> bool:
	if not _buffers.has(action_name):
		return false
		
	var current_time = Time.get_ticks_msec() / 1000.0
	var buffers = _buffers[action_name]
	
	for buffer in buffers:
		if current_time - buffer.timestamp <= DEFAULT_BUFFER_TIME and not buffer.consumed:
			if consume:
				buffer.consumed = true
			return true
	
	return false

## 获取输入缓冲的强度
## [param action_name] 动作名称
## [return] 输入强度，如果没有可用缓冲则返回0
func get_buffer_strength(action_name: String) -> float:
	if not _buffers.has(action_name):
		return 0.0
		
	var current_time = Time.get_ticks_msec() / 1000.0
	var buffers = _buffers[action_name]
	
	for buffer in buffers:
		if current_time - buffer.timestamp <= DEFAULT_BUFFER_TIME and not buffer.consumed:
			return buffer.strength
	
	return 0.0

## 清理过期的输入缓冲
func clean_expired_buffers() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	for action in _buffers.keys():
		var buffers = _buffers[action]
		buffers = buffers.filter(func(buffer): 
			return current_time - buffer.timestamp <= DEFAULT_BUFFER_TIME and not buffer.consumed
		)
		_buffers[action] = buffers

## 清除所有输入缓冲
func clear_buffers() -> void:
	_buffers.clear()