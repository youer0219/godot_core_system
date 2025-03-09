extends Node2D

## 标签系统示例

@onready var tag_manager : CoreSystem.GameplayTagManager = CoreSystem.tag_manager
@onready var player_tags : GameplayTagContainer = $Player/TagContainer
@onready var enemy_tags : GameplayTagContainer = $Enemy/TagContainer
@onready var status_label = $UI/StatusLabel

func _ready() -> void:
	# 注册一些标签
	#tag_manager.register_tag("character.player")
	#tag_manager.register_tag("character.enemy")
	#tag_manager.register_tag("state.idle")
	#tag_manager.register_tag("state.moving")
	#tag_manager.register_tag("state.attacking")
	#tag_manager.register_tag("buff.speed_up")
	#tag_manager.register_tag("buff.attack_up")
	
	# 给玩家添加初始标签
	player_tags.add_tag("character.player")
	player_tags.add_tag("state.idle")
	
	# 给敌人添加初始标签
	enemy_tags.add_tag("character.enemy")
	enemy_tags.add_tag("state.idle")


func _on_player_move_button_pressed() -> void:
	# 切换玩家移动状态
	if player_tags.has_tag("state.moving"):
		player_tags.remove_tag("state.moving")
		player_tags.add_tag("state.idle")
		$Player.modulate = Color.WHITE
		_update_status("Player stopped moving")
	else:
		player_tags.remove_tag("state.idle")
		player_tags.add_tag("state.moving")
		$Player.modulate = Color.GREEN
		_update_status("Player started moving")


func _on_player_attack_button_pressed() -> void:
	# 玩家攻击状态
	if player_tags.has_tag("state.attacking"):
		return
		
	player_tags.add_tag("state.attacking")
	$Player.modulate = Color.RED
	_update_status("Player is attacking!")
	
	# 2秒后移除攻击状态
	await get_tree().create_timer(2.0).timeout
	player_tags.remove_tag("state.attacking")
	$Player.modulate = Color.WHITE if player_tags.has_tag("state.idle") else Color.GREEN
	_update_status("Player finished attacking")


func _on_buff_button_pressed() -> void:
	# 给玩家添加随机增益
	var buffs = ["buff.speed_up", "buff.attack_up"]
	var random_buff = buffs[randi() % buffs.size()]
	
	if player_tags.has_tag(random_buff):
		player_tags.remove_tag(random_buff)
		_update_status("Removed buff: " + random_buff.split(".")[-1])
	else:
		player_tags.add_tag(random_buff)
		_update_status("Added buff: " + random_buff.split(".")[-1])
	
	# 更新buff显示
	_update_buff_display()


func _on_query_button_pressed() -> void:
	# 查询并显示所有标签
	var player_tag_list = player_tags.get_tags()
	var enemy_tag_list = enemy_tags.get_tags()
	
	var status_text = "Player tags: %s\nEnemy tags: %s" % [player_tag_list, enemy_tag_list]
	_update_status(status_text)


func _update_status(text: String) -> void:
	status_label.text = text


func _update_buff_display() -> void:
	var buff_text = ""
	if player_tags.has_tag("buff.speed_up"):
		buff_text += "[Speed Up] "
	if player_tags.has_tag("buff.attack_up"):
		buff_text += "[Attack Up] "
	
	$UI/BuffLabel.text = "Active Buffs: " + (buff_text if not buff_text.is_empty() else "None")
