extends Resource
class_name Trigger

## 触发器

@export var conditions : Array[TriggerCondition] = []
@export var persistent : bool = false
@export var max_triggers : int = -1
@export_storage var trigger_count : int = 0
var _trigger_manager: CoreSystem.TriggerManager:
	get:
		if not _trigger_manager:
			_trigger_manager = CoreSystem.trigger_manager
		return _trigger_manager

signal trigger_success(context: Dictionary)
signal trigger_failed(context: Dictionary)

func _init(config : Dictionary = {}) -> void:
	for condition_config in config.get("conditions", {}):
		var condition : TriggerCondition = _trigger_manager.create_condition(condition_config)
		if condition:
			conditions.append(condition)
	persistent = config.get("persistent", false)
	max_triggers = config.get("max_triggers", -1)
	trigger_count = config.get("trigger_count", 0)

func should_trigger(context : Dictionary) -> bool:
	return conditions.all(func(condition : TriggerCondition) -> bool: return condition.evaluate(context))

func execute(context: Dictionary) -> void:
	if max_triggers > 0 and trigger_count >= max_triggers:
		return
	if should_trigger(context):
		trigger_success.emit(context)
		trigger_count += 1
	else:
		trigger_failed.emit(context)

func reset() -> void:
	trigger_count = 0
