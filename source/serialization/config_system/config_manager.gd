extends "res://addons/godot_core_system/source/manager_base.gd"

## 配置管理器

# 信号
## 配置加载
signal config_loaded
## 配置保存
signal config_saved
## 配置重置
signal config_reset

const DefaultConfig = preload("res://addons/godot_core_system/source/serialization/config_system/default_config.gd")
const AsyncIOManager = preload("res://addons/godot_core_system/source/serialization/io_system/async_io_manager.gd")

## 配置文件路径
@export var config_path: String:
	get:
		return ProjectSettings.get_setting("core_system/config_system/config_path", "user://config.cfg")
	set(value):
		config_path = value

## 是否自动保存
@export var auto_save: bool:
	get:
		return ProjectSettings.get_setting("core_system/config_system/auto_save", true)
	set(value):
		auto_save = value

## 当前配置
var _config: Dictionary = {}
## 异步IO管理器
var _io_manager: AsyncIOManager
## 是否已修改
var _modified: bool = false

func _init():
	_io_manager = AsyncIOManager.new()
	_config = DefaultConfig.get_default_config()

func _exit() -> void:
	if auto_save and _modified:
		save_config()

## 加载配置
## [param callback] 回调函数
func load_config(callback: Callable = func(_success: bool): pass) -> void:
	_io_manager.read_file_async(
		config_path,
		true,
		false,
		"",
		func(success: bool, result: Variant):
			if success:
				# 合并加载的配置和默认配置
				var default_config = DefaultConfig.get_default_config()
				_merge_config(default_config, result)
				_config = default_config
			else:
				# 使用默认配置
				_config = DefaultConfig.get_default_config()
			_modified = false
			config_loaded.emit()
			callback.call(success)
	)

## 保存配置
## [param callback] 回调函数
func save_config(callback: Callable = func(_success: bool): pass) -> void:
	_io_manager.write_file_async(
		config_path,
		_config,
		true,
		false,
		"",
		func(success: bool, _result: Variant):
			if success:
				_modified = false
				config_saved.emit()
			callback.call(success)
	)

## 重置配置
## [param callback] 回调函数
func reset_config(callback: Callable = func(_success: bool): pass) -> void:
	_config = DefaultConfig.get_default_config()
	_modified = true
	config_reset.emit()
	
	if auto_save:
		save_config(callback)
	else:
		callback.call(true)

## 设置配置值
## [param section] 配置段
## [param key] 键
## [param value] 值
func set_value(section: String, key: String, value: Variant) -> void:
	if not _config.has(section):
		_config[section] = {}
	_config[section][key] = value
	_modified = true
	
	if auto_save:
		save_config()

## 获取配置值
## [param section] 配置段
## [param key] 键
## [param default_value] 默认值
## [return] 值
func get_value(section: String, key: String, default_value: Variant = null) -> Variant:
	if _config.has(section) and _config[section].has(key):
		return _config[section][key]
	
	# 从默认配置获取
	var default_config = DefaultConfig.get_default_config()
	if default_config.has(section) and default_config[section].has(key):
		return default_config[section][key]
	
	return default_value

## 删除配置值
## [param section] 配置段
## [param key] 键
func erase_value(section: String, key: String) -> void:
	if _config.has(section):
		_config[section].erase(key)
		_modified = true
		
		if auto_save:
			save_config()

## 获取配置段
## [param section] 配置段
## [return] 配置段
func get_section(section: String) -> Dictionary:
	return _config.get(section, {}).duplicate()

## 合并配置
## [param target] 目标配置
## [param source] 源配置
func _merge_config(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.has(key):
			if source[key] is Dictionary and target[key] is Dictionary:
				_merge_config(target[key], source[key])
			else:
				target[key] = source[key]
