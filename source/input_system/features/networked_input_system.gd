class_name NetworkedInputSystem
extends RefCounted

## 网络输入事件
signal input_received(peer_id: int, input_data: Dictionary)
## 状态同步事件
signal state_synced(peer_id: int, state: Dictionary)
## 输入确认事件
signal input_confirmed(sequence: int, state: Dictionary)
## 状态回滚事件
signal state_rollback(from_sequence: int)

## 输入序列号
var _sequence_number: int = 0
## 输入历史
var _input_history: Array[Dictionary] = []
## 预测状态
var _predicted_states: Dictionary = {}
## 确认状态
var _confirmed_states: Dictionary = {}
## 输入延迟（帧）
var _input_delay: int = 2
## 最大历史记录数
var _max_history: int = 60
## 是否启用预测
var _prediction_enabled: bool = true
## MultiplayerAPI引用
var _multiplayer_api: MultiplayerAPI

## 初始化
## [param api] MultiplayerAPI实例
func setup(api: MultiplayerAPI) -> void:
	_multiplayer_api = api

## 设置输入延迟
## [param frames] 延迟帧数
func set_input_delay(frames: int) -> void:
	_input_delay = frames

## 设置是否启用预测
## [param enabled] 是否启用
func set_prediction_enabled(enabled: bool) -> void:
	_prediction_enabled = enabled

## 发送输入到服务器
## [param input_data] 输入数据
func send_input(input_data: Dictionary) -> void:
	if not _multiplayer_api:
		push_error("NetworkedInputSystem: No MultiplayerAPI set!")
		return

	_sequence_number += 1
	var data = {
		"seq": _sequence_number,
		"timestamp": Time.get_ticks_msec(),
		"inputs": input_data
	}
	
	# 保存到历史记录
	_input_history.append(data)
	if _input_history.size() > _max_history:
		_input_history.pop_front()
	
	# 如果启用了预测，进行本地预测
	if _prediction_enabled:
		_predicted_states[_sequence_number] = predict_state(
			get_last_confirmed_state(),
			input_data
		)
	
	# 通过RPC发送到服务器
	CoreSystem.rpc_id(1, "_receive_client_input", data)

## 接收服务器确认
## [param seq] 序列号
## [param state] 状态数据
func receive_server_confirmation(seq: int, state: Dictionary) -> void:
	_confirmed_states[seq] = state
	input_confirmed.emit(seq, state)
	
	# 检查是否需要回滚
	if _prediction_enabled and _predicted_states.has(seq):
		var predicted = _predicted_states[seq]
		if not states_match(predicted, state):
			rollback_and_replay(seq)

## 预测状态
## [param current_state] 当前状态
## [param input_data] 输入数据
## [return] 预测的状态
func predict_state(current_state: Dictionary, input_data: Dictionary) -> Dictionary:
	# 这个方法需要根据具体游戏逻辑来实现
	# 默认实现直接返回当前状态的副本
	return current_state.duplicate(true)

## 回滚和重放
## [param from_seq] 起始序列号
func rollback_and_replay(from_seq: int) -> void:
	state_rollback.emit(from_seq)
	
	# 清除从这个序列号开始的所有预测状态
	var keys = _predicted_states.keys()
	for seq in keys:
		if seq >= from_seq:
			_predicted_states.erase(seq)
	
	# 重新应用输入进行预测
	var current_state = _confirmed_states[from_seq]
	for input in _input_history:
		if input.seq > from_seq:
			_predicted_states[input.seq] = predict_state(
				current_state,
				input.inputs
			)
			current_state = _predicted_states[input.seq]

## 获取最后确认的状态
## [return] 最后确认的状态
func get_last_confirmed_state() -> Dictionary:
	if _confirmed_states.is_empty():
		return {}
	
	var max_seq = _confirmed_states.keys().max()
	return _confirmed_states[max_seq]

## 清理旧的历史记录
func cleanup_history() -> void:
	var min_seq = _sequence_number - _max_history
	
	# 清理输入历史
	while not _input_history.is_empty() and _input_history[0].seq < min_seq:
		_input_history.pop_front()
	
	# 清理状态历史
	var keys = _confirmed_states.keys()
	for seq in keys:
		if seq < min_seq:
			_confirmed_states.erase(seq)
			_predicted_states.erase(seq)

## 比较两个状态是否匹配
## [param state1] 状态1
## [param state2] 状态2
## [return] 是否匹配
func states_match(state1: Dictionary, state2: Dictionary) -> bool:
	# 这个方法需要根据具体游戏逻辑来实现
	# 默认实现使用简单的字典比较
	return state1.hash() == state2.hash()

## 接收客户端输入（RPC方法）
@rpc("any_peer", "unreliable_ordered")
func _receive_client_input(data: Dictionary) -> void:
	if not _multiplayer_api:
		push_error("NetworkedInputSystem: No MultiplayerAPI set!")
		return
	
	var peer_id = _multiplayer_api.get_remote_sender_id()
	input_received.emit(peer_id, data)

## 发送状态同步（服务器到客户端）
@rpc("authority", "unreliable_ordered")
func _sync_state(seq: int, state: Dictionary) -> void:
	if not _multiplayer_api:
		push_error("NetworkedInputSystem: No MultiplayerAPI set!")
		return
	
	receive_server_confirmation(seq, state)
	state_synced.emit(_multiplayer_api.get_unique_id(), state)