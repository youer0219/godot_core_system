extends Node

## 输入管理器

#region 信号
signal action_triggered(action_name: String, event: InputEvent)
signal axis_changed(axis_name: String, value: Vector2)
signal input_remapped(action_name: String, events: Array[InputEvent])
#endregion

#region 常量
const INPUT_CONFIG_SECTION = "input"
const INPUT_BINDINGS_KEY = "bindings"
#endregion

#region 私有变量
var _virtual_actions: Dictionary = {}
#var _axis_mappings: Dictionary = {}
var _action_states: Dictionary = {}
var _devices: Dictionary = {}

# 模块化管理器
var _virtual_axis: InputVirtualAxis = InputVirtualAxis.new()
var _input_buffer: InputBuffer = InputBuffer.new()
var _input_recorder: InputRecorder = InputRecorder.new()
var _input_state: InputState = InputState.new()
var _event_processor: InputEventProcessor = InputEventProcessor.new()
var _network_input: NetworkedInputSystem = NetworkedInputSystem.new()
var _config_manager: Node = CoreSystem.config_manager
#endregion

#region 生命周期方法
func _ready() -> void:
	_setup_network_connections()
	_initialize_input_actions()
	_setup_config_manager()
	_load_input_config()

func _physics_process(_delta: float) -> void:
	_update_input_state(_delta)

func _input(event: InputEvent) -> void:
	if not _event_processor.process_event(event):
		return
	
	var device_id = _get_device_id_from_event(event)
	_process_action_input(event, device_id)

#endregion

#region 公有方法 - 输入缓冲
func has_input_buffer(action_name: String, consume: bool = true) -> bool:
	return _input_buffer.has_buffer(action_name, consume)

func get_input_buffer_strength(action_name: String) -> float:
	return _input_buffer.get_buffer_strength(action_name)

func add_input_buffer(action_name: String, strength: float = 1.0) -> void:
	_input_buffer.add_buffer(action_name, strength)

func clear_input_buffers() -> void:
	_input_buffer.clear_buffers()
#endregion

#region 公有方法 - 输入记录
func start_recording(actions: Array[String] = []) -> void:
	_input_recorder.start_recording(actions)

func stop_recording() -> void:
	_input_recorder.stop_recording()

func get_input_records() -> Array:
	return _input_recorder.get_records()

func load_input_records(data: Array) -> void:
	_input_recorder.load_records(data)

func clear_input_records() -> void:
	_input_recorder.clear_records()

func get_recording_duration() -> float:
	return _input_recorder.get_duration()

func is_recording() -> bool:
	return _input_recorder.is_recording()

func get_input_state_at_time(time: float) -> Dictionary:
	return _input_recorder.get_state_at_time(time)
#endregion

#region 公有方法 - 动作状态
func is_action_pressed(action_name: String) -> bool:
	return _input_state.is_pressed(action_name)

func get_action_press_time(action_name: String) -> float:
	return _input_state.get_press_time(action_name)

func get_action_press_count(action_name: String) -> int:
	return _input_state.get_press_count(action_name)

func get_action_state(action_name: String) -> Dictionary:
	return _input_state.get_action_state(action_name)

func reset_action_state(action_name: String) -> void:
	_input_state.reset_action(action_name)

func create_state_snapshot() -> Dictionary:
	return _input_state.create_snapshot()

func restore_state_from_snapshot(snapshot: Dictionary) -> void:
	_input_state.restore_from_snapshot(snapshot)
#endregion

#region 公有方法 - 动作管理
## 注册新的输入动作
## [param action_name] 动作名称
## [param events] 输入事件列表（可选）
func register_action(action_name: String, events: Array[InputEvent] = []) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		for event in events:
			InputMap.action_add_event(action_name, event)
		_input_state.init_action(action_name)

## 注销输入动作
## [param action_name] 动作名称
func unregister_action(action_name: String) -> void:
	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)

## 检查动作是否已注册
## [param action_name] 动作名称
## [return] 是否已注册
func has_action(action_name: String) -> bool:
	return InputMap.has_action(action_name)

## 检查动作是否刚刚被按下
## [param action_name] 动作名称
## [return] 是否刚刚按下
func is_action_just_pressed(action_name: String) -> bool:
	if not _input_state:
		return false
	return _input_state.is_just_pressed(action_name)

## 检查动作是否刚刚被释放
## [param action_name] 动作名称
## [return] 是否刚刚释放
func is_action_just_released(action_name: String) -> bool:
	if not _input_state:
		return false
	return _input_state.is_just_released(action_name)
#endregion

## 获取动作的输入强度
## [param action_name] 动作名称
## [return] 输入强度
func get_action_strength(action_name: String) -> float:
	return _input_state.get_strength(action_name)

## 重置所有动作状态
func reset_all_states() -> void:
	_input_state.reset_all()
#endregion

#region 公有方法 - 输入缓冲管理
## 设置输入缓冲时间
## [param duration] 缓冲时间（秒）
func set_input_buffer_duration(duration: float) -> void:
	_input_buffer.set_buffer_duration(duration)

## 获取输入缓冲时间
## [return] 缓冲时间（秒）
func get_input_buffer_duration() -> float:
	return _input_buffer.get_buffer_duration()

## 清除指定动作的输入缓冲
## [param action_name] 动作名称
func clear_action_buffer(action_name: String) -> void:
	_input_buffer.clear_action_buffer(action_name)
#endregion

#region 公有方法 - 设备管理
## 获取设备的动作状态
## [param device_id] 设备ID
## [param action] 动作名称
## [return] 动作状态
func get_device_action_state(device_id: int, action: String) -> Dictionary:
	if _devices.has(device_id):
		return _devices[device_id].get_action_state(action)
	return {}

## 获取设备的所有动作状态
## [param device_id] 设备ID
## [return] 所有动作状态
func get_device_states(device_id: int) -> Dictionary:
	if _devices.has(device_id):
		return _devices[device_id].get_all_states()
	return {}

## 重置设备状态
## [param device_id] 设备ID
func reset_device_state(device_id: int) -> void:
	if _devices.has(device_id):
		_devices[device_id].reset_all()
#endregion

#region 公有方法 - 事件处理
func add_event_handler(handler: InputEventProcessor.InputEventHandler) -> void:
	_event_processor.add_handler(handler)

func remove_event_handler(handler: InputEventProcessor.InputEventHandler) -> void:
	_event_processor.remove_handler(handler)

func add_event_filter(filter: InputEventProcessor.InputFilter) -> void:
	_event_processor.add_filter(filter)

func remove_event_filter(filter: InputEventProcessor.InputFilter) -> void:
	_event_processor.remove_filter(filter)

func create_key_remap_handler() -> InputEventProcessor.KeyRemapHandler:
	var handler = InputEventProcessor.KeyRemapHandler.new()
	add_event_handler(handler)
	return handler

func create_key_combo_handler() -> InputEventProcessor.KeyComboHandler:
	var handler = InputEventProcessor.KeyComboHandler.new()
	add_event_handler(handler)
	return handler

func create_gesture_handler() -> InputEventProcessor.GestureHandler:
	var handler = InputEventProcessor.GestureHandler.new()
	add_event_handler(handler)
	return handler

func create_key_filter() -> InputEventProcessor.KeyFilter:
	var filter = InputEventProcessor.KeyFilter.new()
	add_event_filter(filter)
	return filter

func create_action_filter() -> InputEventProcessor.ActionFilter:
	var filter = InputEventProcessor.ActionFilter.new()
	add_event_filter(filter)
	return filter
#endregion

#region 公有方法 - 设备管理
func register_device(device: InputDevice) -> void:
	_devices[device.device_id] = device

func unregister_device(device_id: int) -> void:
	if _devices.has(device_id):
		_devices[device_id].disconnect_device()
		_devices.erase(device_id)

func get_device(device_id: int) -> InputDevice:
	return _devices.get(device_id)

func get_all_devices() -> Array[InputDevice]:
	return _devices.values()

func is_device_action_pressed(device_id: int, action: String) -> bool:
	if _devices.has(device_id):
		return _devices[device_id].is_action_pressed(action)
	return false

func get_device_action_strength(device_id: int, action: String) -> float:
	if _devices.has(device_id):
		return _devices[device_id].get_action_strength(action)
	return 0.0
#endregion

#region 公有方法 - 输入重映射
func remap_action(action_name: String, events: Array[InputEvent]) -> void:
	if not InputMap.has_action(action_name):
		push_warning("尝试重映射不存在的动作：%s" % action_name)
		return
	
	_update_input_map(action_name, events)
	_save_input_config(action_name, events)
	input_remapped.emit(action_name, events)
#endregion

#region 公有方法 - 虚拟轴
func register_axis(axis_name: String, positive_x: String, negative_x: String, 
	positive_y: String, negative_y: String) -> void:
	_virtual_axis.register_axis(axis_name, positive_x, negative_x, positive_y, negative_y)

func unregister_axis(axis_name: String) -> void:
	_virtual_axis.unregister_axis(axis_name)

func clear_axis(axis_name: String = "") -> void:
	_virtual_axis.clear_axis(axis_name)

func get_axis_value(axis_name: String) -> Vector2:
	return _virtual_axis.get_axis(axis_name)

func get_axis_mapping(axis_name: String) -> Dictionary:
	return _virtual_axis.get_axis_mapping(axis_name)

func get_axis_mappings() -> Dictionary:
	return _virtual_axis.get_axis_mappings()

func set_axis_mapping(axis_name: String, mapping: Dictionary) -> void:
	_virtual_axis.set_axis_mapping(axis_name, mapping)

func get_axis_sensitivity() -> float:
	return _virtual_axis.get_sensitivity()

func set_axis_sensitivity(value: float) -> void:
	_virtual_axis.set_sensitivity(value)

func get_axis_deadzone() -> float:
	return _virtual_axis.get_deadzone()

func set_axis_deadzone(value: float) -> void:
	_virtual_axis.set_deadzone(value)
#endregion

#region 私有方法 - 初始化
func _setup_network_connections() -> void:
	_network_input.input_received.connect(_on_network_input_received)
	_network_input.state_synced.connect(_on_network_state_synced)
	_network_input.state_rollback.connect(_on_network_state_rollback)

func _initialize_input_actions() -> void:
	for action in InputMap.get_actions():
		_input_state.init_action(action)

func _setup_config_manager() -> void:
	_config_manager.config_loaded.connect(_on_config_loaded)
#endregion

#region 私有方法 - 输入处理

## 更新输入状态
## [param delta] 时间增量
func _update_input_state(delta: float) -> void:
	_input_buffer.clean_expired_buffers()
	
	# 更新轴状态
	for axis_name in _virtual_axis.get_registered_axes():
		_virtual_axis.update_axis(axis_name, self)
	
	# 更新设备状态
	for device in _devices.values():
		if device.connected:
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - device.last_input_time > 1.0:
				device.reset_all()

## 从事件获取设备ID
## [param event] 输入事件
## [return] 设备ID
func _get_device_id_from_event(event: InputEvent) -> int:
	if event is InputEventJoypadButton:
		return event.device + 1  # 手柄设备ID从1开始
	return 0  # 键盘鼠标使用设备ID 0

## 处理动作输入
## [param event] 输入事件
## [param device_id] 设备ID
func _process_action_input(event: InputEvent, device_id: int) -> void:
	if not event.is_action_type():
		return
		
	for action in InputMap.get_actions():
		if event.is_action(action):
			var just_pressed = event.is_action_pressed(action)
			var just_released = event.is_action_released(action)
			var strength = event.get_action_strength(action)
			
			if just_pressed or just_released:
				# 更新设备状态
				if _devices.has(device_id):
					_devices[device_id].update_state(action, just_pressed, strength)
				
				# 更新输入状态
				_input_state.update_action(action, just_pressed, strength)
				
				# 处理输入缓冲
				if just_pressed:
					_input_buffer.add_buffer(action, strength)
				
				# 记录输入
				_input_recorder.record_input(action, just_pressed, strength)
				
				# 发送信号
				action_triggered.emit(action, event)
				
				# 处理网络同步
				if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
					_network_input.send_input({
						"action": action,
						"pressed": just_pressed,
						"strength": strength,
						"device_id": device_id
					})
#endregion

#region 私有方法 - 配置管理
func _load_input_config() -> void:
	var input_config = _config_manager.get_section(INPUT_CONFIG_SECTION)
	if not input_config:
		return
		
	var bindings = input_config.get(INPUT_BINDINGS_KEY, {})
	for action in bindings:
		if InputMap.has_action(action):
			var events = _create_input_events(bindings[action])
			if not events.is_empty():
				_update_input_map(action, events)

func _update_input_map(action: String, events: Array[InputEvent]) -> void:
	InputMap.action_erase_events(action)
	for event in events:
		InputMap.action_add_event(action, event)

func _save_input_config(action_name: String, events: Array[InputEvent]) -> void:
	var input_config = _config_manager.get_section(INPUT_CONFIG_SECTION) or {}
	var bindings = input_config.get(INPUT_BINDINGS_KEY, {})
	bindings[action_name] = _serialize_input_events(events)
	input_config[INPUT_BINDINGS_KEY] = bindings
	_config_manager.set_section(INPUT_CONFIG_SECTION, input_config)

func _create_input_events(events_data: Array) -> Array[InputEvent]:
	var result: Array[InputEvent] = []
	for event_data in events_data:
		var event = _create_single_input_event(event_data)
		if event:
			result.append(event)
	return result

func _create_single_input_event(event_data: Dictionary) -> InputEvent:
	match event_data.type:
		"key":
			var event = InputEventKey.new()
			event.keycode = event_data.keycode
			event.physical_keycode = event_data.physical_keycode
			event.key_label = event_data.key_label
			event.unicode = event_data.unicode
			return event
		"joypad_button":
			var event = InputEventJoypadButton.new()
			event.button_index = event_data.button_index
			event.pressure = event_data.get("pressure", 1.0)
			return event
	return null

func _serialize_input_events(events: Array[InputEvent]) -> Array:
	var result = []
	for event in events:
		var serialized = _serialize_single_input_event(event)
		if serialized:
			result.append(serialized)
	return result

func _serialize_single_input_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {
			"type": "key",
			"keycode": event.keycode,
			"physical_keycode": event.physical_keycode,
			"key_label": event.key_label,
			"unicode": event.unicode
		}
	elif event is InputEventJoypadButton:
		return {
			"type": "joypad_button",
			"button_index": event.button_index,
			"pressure": event.pressure
		}
	return {}
#endregion

#region 私有方法 - 回调函数
func _on_config_loaded() -> void:
	_load_input_config()

func _on_network_input_received(peer_id: int, input_data: Dictionary) -> void:
	var action = input_data.action
	var pressed = input_data.pressed
	var strength = input_data.strength
	var device_id = input_data.device_id
	
	_update_device_state(device_id, action, pressed, strength)
	_input_state.update_action(action, pressed, strength)
	action_triggered.emit(action, null)

func _on_network_state_synced(peer_id: int, state: Dictionary) -> void:
	_input_state.restore_from_snapshot(state.get("input_state", {}))
	
	var devices_state = state.get("devices_state", {})
	for device_id in devices_state:
		if _devices.has(device_id):
			_devices[device_id].restore_from_snapshot(devices_state[device_id])

func _on_network_state_rollback(from_sequence: int) -> void:
	var confirmed_state = _network_input.get_last_confirmed_state()
	_on_network_state_synced(multiplayer.get_unique_id(), confirmed_state)
#endregion
