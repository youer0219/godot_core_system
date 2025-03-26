extends Node

## 输入管理器


## 动作触发
signal action_triggered(action_name: String, event: InputEvent)
## 轴变化
signal axis_changed(axis_name: String, value: Vector2)
## 输入重映射
signal input_remapped(action_name: String, events: Array[InputEvent])

## 默认缓冲时间
const DEFAULT_BUFFER_TIME = 0.15  # 150ms的输入缓冲时间
## 输入配置-section
const INPUT_CONFIG_SECTION = "input"
const INPUT_BINDINGS_KEY = "bindings"

## 虚拟动作
var _virtual_actions: Dictionary = {}
## 轴映射
var _axis_mappings: Dictionary = {}
## 动作状态
var _action_states: Dictionary = {}
## 输入缓冲管理器
var _input_buffer: InputBuffer
## 配置管理器
var _config_manager: Node = CoreSystem.config_manager
## 虚拟轴管理器
var _virtual_axis: VirtualAxis
## 输入记录器
var _input_recorder: InputRecorder
## 输入状态管理器
var _input_state: InputState
## 输入事件处理器
var _event_processor: InputEventProcessor
## 输入设备列表
var _devices: Dictionary = {}
## 网络输入系统
var _network_input: NetworkedInputSystem

func _init() -> void:
	_input_buffer = InputBuffer.new()
	_virtual_axis = VirtualAxis.new()
	_input_recorder = InputRecorder.new()
	_input_state = InputState.new()
	_event_processor = InputEventProcessor.new()
	_network_input = NetworkedInputSystem.new()
	
	# 连接网络输入信号
	_network_input.input_received.connect(_on_network_input_received)
	_network_input.state_synced.connect(_on_network_state_synced)
	_network_input.state_rollback.connect(_on_network_state_rollback)

func _ready() -> void:
	# 初始化所有已注册的输入动作状态
	for action in InputMap.get_actions():
		_input_state.init_action(action)
	
	# 订阅配置加载事件
	_config_manager.config_loaded.connect(_on_config_loaded)
	
	# 加载输入配置
	_load_input_config()

func _physics_process(_delta: float) -> void:
	# 清理过期的输入缓冲
	_input_buffer.clean_expired_buffers()
	_update_axis_state(_delta)

func _input(event: InputEvent) -> void:
	# 首先通过事件处理器处理事件
	if not _event_processor.process_event(event):
		return
	
	# 获取设备ID
	var device_id = _get_device_id_from_event(event)
	
	# 处理所有已注册的输入动作
	for action in InputMap.get_actions():
		if event.is_action_type():
			var just_pressed = event.is_action_pressed(action)
			var just_released = event.is_action_released(action)
			var strength = event.get_action_strength(action) if event.is_action(action) else 0.0
			
			# 更新设备状态
			if _devices.has(device_id):
				_devices[device_id].update_state(action, just_pressed, strength)
			
			if just_pressed:
				_input_state.update_action(action, true, strength)
				_input_buffer.add_buffer(action, strength)
				_input_recorder.record_input(action, true, strength)
				
				# 发送网络输入
				if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
					_network_input.send_input({
						"action": action,
						"pressed": true,
						"strength": strength,
						"device_id": device_id
					})
				
				action_triggered.emit(action, event)
			elif just_released:
				_input_state.update_action(action, false, 0.0)
				_input_recorder.record_input(action, false, 0.0)
				
				# 发送网络输入
				if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
					_network_input.send_input({
						"action": action,
						"pressed": false,
						"strength": 0.0,
						"device_id": device_id
					})
				
				action_triggered.emit(action, event)

	# 处理虚拟轴输入
	_process_axis_input()

## 重映射输入动作
## [param action_name] 动作名称
## [param events] 输入事件列表
func remap_action(action_name: String, events: Array[InputEvent]) -> void:
	if not InputMap.has_action(action_name):
		push_warning("尝试重映射不存在的动作：%s" % action_name)
		return
	
	# 清除现有的映射
	InputMap.action_erase_events(action_name)
	
	# 添加新的映射
	for event in events:
		InputMap.action_add_event(action_name, event)
	
	# 保存到配置
	var input_config = _config_manager.get_section(INPUT_CONFIG_SECTION)
	if not input_config:
		input_config = {}
	
	var bindings = input_config.get(INPUT_BINDINGS_KEY, {})
	bindings[action_name] = _serialize_input_events(events)
	input_config[INPUT_BINDINGS_KEY] = bindings
	
	_config_manager.set_section(INPUT_CONFIG_SECTION, input_config)
	
	# 发送信号
	input_remapped.emit(action_name, events)

## 注册轴
## [param axis_name] 轴名称
## [param positive_x] 正X轴动作名称
## [param negative_x] 负X轴动作名称
## [param positive_y] 正Y轴动作名称
## [param negative_y] 负Y轴动作名称
func register_axis(axis_name: String, positive_x: String, negative_x: String, 
	positive_y: String, negative_y: String) -> void:
	_virtual_axis.register_axis(axis_name, positive_x, negative_x, positive_y, negative_y)

## 注销轴
## [param axis_name] 轴名称
func unregister_axis(axis_name: String) -> void:
	_virtual_axis.unregister_axis(axis_name)

## 清除轴
## [param axis_name] 轴名称，如果为空则清除所有轴
func clear_axis(axis_name: String = "") -> void:
	_virtual_axis.clear_axis(axis_name)

## 获取轴值
## [param axis_name] 轴名称
## [return] 轴值
func get_axis_value(axis_name: String) -> Vector2:
	return _virtual_axis.get_axis(axis_name)

## 获取轴映射
## [param axis_name] 轴名称
## [return] 轴映射数据
func get_axis_mapping(axis_name: String) -> Dictionary:
	return _virtual_axis.get_axis_mapping(axis_name)

## 获取所有轴映射
## [return] 所有轴映射数据
func get_axis_mappings() -> Dictionary:
	return _virtual_axis.get_axis_mappings()

## 设置轴映射
## [param axis_name] 轴名称
## [param mapping] 轴映射数据
func set_axis_mapping(axis_name: String, mapping: Dictionary) -> void:
	_virtual_axis.set_axis_mapping(axis_name, mapping)

## 获取轴灵敏度
## [return] 轴灵敏度值
func get_axis_sensitivity() -> float:
	return _virtual_axis.get_sensitivity()

## 设置轴灵敏度
## [param value] 灵敏度值
func set_axis_sensitivity(value: float) -> void:
	_virtual_axis.set_sensitivity(value)

## 获取轴死区
## [return] 死区值
func get_axis_deadzone() -> float:
	return _virtual_axis.get_deadzone()

## 设置轴死区
## [param value] 死区值
func set_axis_deadzone(value: float) -> void:
	_virtual_axis.set_deadzone(value)

## 更新轴状态
## [param delta] 时间增量
func _update_axis_state(delta: float) -> void:
	for axis_name in _virtual_axis.get_registered_axes():
		_virtual_axis.update_axis(axis_name, self)

## 处理虚拟轴输入
func _process_axis_input() -> void:
	for axis_name in _virtual_axis.get_registered_axes():
		var value = get_axis_value(axis_name)
		if value != Vector2.ZERO:
			axis_changed.emit(axis_name, value)

## 开始记录输入
## [param actions] 要记录的动作列表，如果为空则记录所有动作
func start_recording(actions: Array[String] = []) -> void:
	_input_recorder.start_recording(actions)

## 停止记录输入
func stop_recording() -> void:
	_input_recorder.stop_recording()

## 获取输入记录
## [return] 记录数据
func get_input_records() -> Array:
	return _input_recorder.get_records()

## 从数据加载输入记录
## [param data] 记录数据
func load_input_records(data: Array) -> void:
	_input_recorder.load_records(data)

## 清除输入记录
func clear_input_records() -> void:
	_input_recorder.clear_records()

## 获取记录时长
## [return] 记录时长（秒）
func get_recording_duration() -> float:
	return _input_recorder.get_duration()

## 是否正在记录
## [return] 是否正在记录
func is_recording() -> bool:
	return _input_recorder.is_recording()

## 获取指定时间点的输入状态
## [param time] 时间点
## [return] 输入状态
func get_input_state_at_time(time: float) -> Dictionary:
	return _input_recorder.get_state_at_time(time)

## 检查输入缓冲
## [param action_name] 动作名称
## [param consume] 是否消耗缓冲
## [return] 如果有可用的输入缓冲返回true
func has_input_buffer(action_name: String, consume: bool = true) -> bool:
	return _input_buffer.has_buffer(action_name, consume)

## 获取输入缓冲的强度
## [param action_name] 动作名称
## [return] 输入强度
func get_input_buffer_strength(action_name: String) -> float:
	return _input_buffer.get_buffer_strength(action_name)

## 添加输入缓冲
## [param action_name] 动作名称
## [param strength] 输入强度
func add_input_buffer(action_name: String, strength: float = 1.0) -> void:
	_input_buffer.add_buffer(action_name, strength)

## 清除所有输入缓冲
func clear_input_buffers() -> void:
	_input_buffer.clear_buffers()

## 检查动作是否正在被按下
## [param action_name] 动作名称
## [return] 是否正在被按下
func is_action_pressed(action_name: String) -> bool:
	return _input_state.is_pressed(action_name)

## 获取动作按下时长
## [param action_name] 动作名称
## [return] 按下时长（秒）
func get_action_press_time(action_name: String) -> float:
	return _input_state.get_press_time(action_name)

## 获取动作按下次数
## [param action_name] 动作名称
## [return] 按下次数
func get_action_press_count(action_name: String) -> int:
	return _input_state.get_press_count(action_name)

## 获取动作状态
## [param action_name] 动作名称
## [return] 动作状态
func get_action_state(action_name: String) -> Dictionary:
	return _input_state.get_action_state(action_name)

## 重置动作状态
## [param action_name] 动作名称
func reset_action_state(action_name: String) -> void:
	_input_state.reset_action(action_name)

## 创建输入状态快照
## [return] 状态快照
func create_state_snapshot() -> Dictionary:
	return _input_state.create_snapshot()

## 从快照恢复输入状态
## [param snapshot] 状态快照
func restore_state_from_snapshot(snapshot: Dictionary) -> void:
	_input_state.restore_from_snapshot(snapshot)

## 添加输入事件处理器
## [param handler] 事件处理器
func add_event_handler(handler: InputEventProcessor.InputEventHandler) -> void:
	_event_processor.add_handler(handler)

## 移除输入事件处理器
## [param handler] 事件处理器
func remove_event_handler(handler: InputEventProcessor.InputEventHandler) -> void:
	_event_processor.remove_handler(handler)

## 添加输入事件过滤器
## [param filter] 事件过滤器
func add_event_filter(filter: InputEventProcessor.InputFilter) -> void:
	_event_processor.add_filter(filter)

## 移除输入事件过滤器
## [param filter] 事件过滤器
func remove_event_filter(filter: InputEventProcessor.InputFilter) -> void:
	_event_processor.remove_filter(filter)

## 创建按键重映射处理器
## [return] 按键重映射处理器
func create_key_remap_handler() -> InputEventProcessor.KeyRemapHandler:
	var handler = InputEventProcessor.KeyRemapHandler.new()
	add_event_handler(handler)
	return handler

## 创建按键组合处理器
## [return] 按键组合处理器
func create_key_combo_handler() -> InputEventProcessor.KeyComboHandler:
	var handler = InputEventProcessor.KeyComboHandler.new()
	add_event_handler(handler)
	return handler

## 创建手势处理器
## [return] 手势处理器
func create_gesture_handler() -> InputEventProcessor.GestureHandler:
	var handler = InputEventProcessor.GestureHandler.new()
	add_event_handler(handler)
	return handler

## 创建按键过滤器
## [return] 按键过滤器
func create_key_filter() -> InputEventProcessor.KeyFilter:
	var filter = InputEventProcessor.KeyFilter.new()
	add_event_filter(filter)
	return filter

## 创建动作过滤器
## [return] 动作过滤器
func create_action_filter() -> InputEventProcessor.ActionFilter:
	var filter = InputEventProcessor.ActionFilter.new()
	add_event_filter(filter)
	return filter

## 注册输入设备
## [param device] 输入设备
func register_device(device: InputDevice) -> void:
	_devices[device.device_id] = device

## 注销输入设备
## [param device_id] 设备ID
func unregister_device(device_id: int) -> void:
	if _devices.has(device_id):
		_devices[device_id].disconnect_device()
		_devices.erase(device_id)

## 获取输入设备
## [param device_id] 设备ID
## [return] 输入设备
func get_device(device_id: int) -> InputDevice:
	return _devices.get(device_id)

## 获取所有设备
## [return] 设备列表
func get_all_devices() -> Array[InputDevice]:
	return _devices.values()

## 获取设备的动作状态
## [param device_id] 设备ID
## [param action] 动作名称
## [return] 动作状态
func get_device_action_state(device_id: int, action: String) -> Dictionary:
	if _devices.has(device_id):
		return _devices[device_id].get_action_state(action)
	return {}

## 检查设备的动作是否按下
## [param device_id] 设备ID
## [param action] 动作名称
## [return] 是否按下
func is_device_action_pressed(device_id: int, action: String) -> bool:
	if _devices.has(device_id):
		return _devices[device_id].is_action_pressed(action)
	return false

## 获取设备的动作强度
## [param device_id] 设备ID
## [param action] 动作名称
## [return] 动作强度
func get_device_action_strength(device_id: int, action: String) -> float:
	if _devices.has(device_id):
		return _devices[device_id].get_action_strength(action)
	return 0.0

## 从事件获取设备ID
## [param event] 输入事件
## [return] 设备ID
func _get_device_id_from_event(event: InputEvent) -> int:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return event.device + 1  # Joypad设备ID从1开始
	return 0  # 键鼠设备ID为0

## 加载输入配置
func _load_input_config() -> void:
	var input_config = _config_manager.get_section(INPUT_CONFIG_SECTION)
	if not input_config:
		return
		
	var bindings = input_config.get(INPUT_BINDINGS_KEY, {})
	for action in bindings:
		if InputMap.has_action(action):
			var events = _create_input_events(bindings[action])
			if not events.is_empty():
				# 清除现有的映射
				InputMap.action_erase_events(action)
				# 添加保存的映射
				for event in events:
					InputMap.action_add_event(action, event)

## 从配置创建输入事件
## [param event_data] 事件数据
## [return] 输入事件列表
func _create_input_events(events_data: Array) -> Array[InputEvent]:
	var result: Array[InputEvent] = []
	
	for event_data in events_data:
		if event_data.type == "key":
			var event = InputEventKey.new()
			event.keycode = event_data.keycode
			event.physical_keycode = event_data.physical_keycode
			event.key_label = event_data.key_label
			event.unicode = event_data.unicode
			result.append(event)
		elif event_data.type == "joypad_button":
			var event = InputEventJoypadButton.new()
			event.button_index = event_data.button_index
			event.pressure = event_data.get("pressure", 1.0)  # 添加默认值支持
			result.append(event)
	
	return result

## 序列化输入事件
## [param events] 输入事件列表
## [return] 序列化后的事件数据
func _serialize_input_events(events: Array[InputEvent]) -> Array:
	var result = []
	
	for event in events:
		if event is InputEventKey:
			result.append({
				"type": "key",
				"keycode": event.keycode,
				"physical_keycode": event.physical_keycode,
				"key_label": event.key_label,
				"unicode": event.unicode
			})
		elif event is InputEventJoypadButton:
			result.append({
				"type": "joypad_button",
				"button_index": event.button_index,
				"pressure": event.pressure
			})
	
	return result

## 配置加载回调
func _on_config_loaded() -> void:
	_load_input_config()

## 网络输入接收回调
## [param peer_id] 对等体ID
## [param input_data] 输入数据
func _on_network_input_received(peer_id: int, input_data: Dictionary) -> void:
	var action = input_data.action
	var pressed = input_data.pressed
	var strength = input_data.strength
	var device_id = input_data.device_id
	
	# 更新设备状态
	if _devices.has(device_id):
		_devices[device_id].update_state(action, pressed, strength)
	
	# 更新输入状态
	_input_state.update_action(action, pressed, strength)
	
	if pressed:
		action_triggered.emit(action, null)  # 没有原始事件
	else:
		action_triggered.emit(action, null)

## 网络状态同步回调
## [param peer_id] 对等体ID
## [param state] 状态数据
func _on_network_state_synced(peer_id: int, state: Dictionary) -> void:
	# 恢复输入状态
	_input_state.restore_from_snapshot(state.get("input_state", {}))
	
	# 恢复设备状态
	var devices_state = state.get("devices_state", {})
	for device_id in devices_state:
		if _devices.has(device_id):
			_devices[device_id].restore_from_snapshot(devices_state[device_id])

## 网络状态回滚回调
## [param from_sequence] 起始序列号
func _on_network_state_rollback(from_sequence: int) -> void:
	# 重置到确认状态
	var confirmed_state = _network_input.get_last_confirmed_state()
	_on_network_state_synced(multiplayer.get_unique_id(), confirmed_state)
