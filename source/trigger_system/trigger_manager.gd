extends Node

## 触发器集
@export_storage var _triggers : Dictionary[StringName, Array]
var _condition_types : Dictionary = {
	"composite_trigger_condition": CompositeTriggerCondition,
	"event_type_trigger_condition": EventTypeTriggerCondition,
	"state_trigger_condition": StateTriggerCondition,
}

signal trigger_success(trigger: Trigger, context: Dictionary)
signal trigger_failed(trigger: Trigger, context: Dictionary)

## 触发
func handle_event(trigger_type: StringName, context: Dictionary) -> void:
	var triggers : Array = _triggers.get(trigger_type, [])
	if triggers.is_empty():
		return
	for trigger : Trigger in triggers:
		trigger.execute(context)


## 添加触发器
func register_trigger(trigger_type: StringName, trigger: Trigger) -> void:
	trigger.trigger_success.connect(_on_trigger_success.bind(trigger))
	trigger.trigger_failed.connect(_on_trigger_failed.bind(trigger))
	if not _triggers.has(trigger_type):
		_triggers[trigger_type] = []
	_triggers[trigger_type].append(trigger)


## 移除触发器
func unregister_trigger(trigger_type: StringName, trigger: Trigger) -> void:
	trigger.trigger_success.disconnect(_on_trigger_success.bind(trigger))
	trigger.trigger_failed.disconnect(_on_trigger_failed.bind(trigger))
	var triggers : Array[Trigger] = _triggers.get(trigger_type, [])
	if triggers.has(trigger):
		triggers.erase(trigger)

## 注册限制器类型
## [param type] 限制器类型
## [param condition_class] 限制器类
func register_condition_type(type: StringName, condition_class: GDScript) -> void:
	_condition_types[type] = condition_class


## 卸载限制器类型
func unregister_condition_type(type: StringName) -> void:
	_condition_types.erase(type)


## 创建限制器
func create_condition(config: Dictionary) -> TriggerCondition:
	var condition_type : StringName = config.get("type")
	if not _condition_types.has(condition_type):
		return null
	return _condition_types[condition_type].new(config)


func _on_trigger_success(context: Dictionary, trigger: Trigger) -> void:
	trigger_success.emit(trigger, context)


func _on_trigger_failed(context: Dictionary, trigger: Trigger) -> void:
	trigger_failed.emit(trigger, context)
