extends TriggerCondition
class_name StateTriggerCondition

## 状态触发条件，条件示例

## 状态名称
@export var state_name : StringName
## 状态值
@export var required_state : StringName

func _init(config : Dictionary = {}) -> void:
	state_name = config.get("state_name", "")
	required_state = config.get("required_state", "")

func evaluate(context: Dictionary) -> bool:
	var entity = context.get("entity", null)
	if not entity:
		return false
	return entity.get(state_name) == required_state
