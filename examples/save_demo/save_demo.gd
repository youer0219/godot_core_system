extends Node2D

const SaveManager = CoreSystem.SaveManager

@onready var save_manager : SaveManager = CoreSystem.save_manager
@onready var status_label = $UI/StatusLabel
@onready var save_list = $UI/SaveList
@onready var player_data = $PlayerData

func _ready():
	# 连接信号
	save_manager.save_created.connect(_on_save_created)
	save_manager.save_loaded.connect(_on_save_loaded)
	save_manager.save_deleted.connect(_on_save_deleted)
	save_manager.auto_save_created.connect(_on_auto_save_created)
	
	# 更新存档列表
	_update_save_list()

## 更新存档列表
func _update_save_list():
	save_list.clear()
	save_manager.get_save_list(func(saves: Array):
		for save_name in saves:
			var item = save_list.add_item(save_name)
	)

## 创建新存档按钮回调
func _on_create_button_pressed():
	var timestamp = Time.get_unix_time_from_system()
	var save_name = "save_%d" % timestamp
	
	status_label.text = "正在创建存档..."
	save_manager.create_save(save_name, func(success: bool):
		status_label.text = "存档创建" + ("成功" if success else "失败")
		if success:
			_update_save_list()
	)

## 加载存档按钮回调
func _on_load_button_pressed():
	var selected_items = save_list.get_selected_items()
	if selected_items.is_empty():
		status_label.text = "请先选择一个存档"
		return
	
	var save_name = save_list.get_item_text(selected_items[0])
	status_label.text = "正在加载存档..."
	save_manager.load_save(save_name, func(success: bool):
		status_label.text = "存档加载" + ("成功" if success else "失败")
	)

## 删除存档按钮回调
func _on_delete_button_pressed():
	var selected_items = save_list.get_selected_items()
	if selected_items.is_empty():
		status_label.text = "请先选择一个存档"
		return
	
	var save_name = save_list.get_item_text(selected_items[0])
	status_label.text = "正在删除存档..."
	save_manager.delete_save(save_name, func(success: bool):
		status_label.text = "存档删除" + ("成功" if success else "失败")
		if success:
			_update_save_list()
	)

## 切换自动存档按钮回调
func _on_auto_save_toggled(button_pressed: bool):
	ProjectSettings.set_setting("core_system/save_system/auto_save_enabled", button_pressed)
	status_label.text = "自动存档已" + ("开启" if button_pressed else "关闭")

## 存档创建回调
func _on_save_created(save_name: String):
	print("存档已创建：", save_name)

## 存档加载回调
func _on_save_loaded(save_name: String):
	print("存档已加载：", save_name)

## 存档删除回调
func _on_save_deleted(save_name: String):
	print("存档已删除：", save_name)

## 自动存档创建回调
func _on_auto_save_created():
	status_label.text = "自动存档已创建"
	_update_save_list()
