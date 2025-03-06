extends SerializableComponent

## 玩家数据组件（用于演示存档系统）

var player_name: String = "Player"
var player_level: int = 1
var player_exp: int = 0
var player_position: Vector2 = Vector2.ZERO

func _ready():
	# 将节点添加到可序列化组
	add_to_group("serializable")

## 序列化数据
func serialize() -> Dictionary:
	return {
		"name": player_name,
		"level": player_level,
		"exp": player_exp,
		"position": {
			"x": player_position.x,
			"y": player_position.y
		}
	}

## 反序列化数据
func deserialize(data: Dictionary) -> void:
	player_name = data.get("name", player_name)
	player_level = data.get("level", player_level)
	player_exp = data.get("exp", player_exp)
	
	var pos = data.get("position", {})
	player_position.x = pos.get("x", player_position.x)
	player_position.y = pos.get("y", player_position.y)
	
	print("玩家数据已加载：")
	print("- 名称：", player_name)
	print("- 等级：", player_level)
	print("- 经验：", player_exp)
	print("- 位置：", player_position)
