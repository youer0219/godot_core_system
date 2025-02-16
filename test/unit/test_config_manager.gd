extends GutTest

const TEST_CONFIG_PATH := "user://test_config.cfg"
const TEST_CONFIG_DATA := {
	"graphics": {
		"resolution": Vector2(1920, 1080),
		"fullscreen": false,
		"vsync": true
	},
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.9
	},
	"gameplay": {
		"difficulty": "normal",
		"language": "en"
	}
}

var _config_manager: CoreSystem.ConfigManager

func before_each():
	_config_manager = CoreSystem.config_manager
	_config_manager.config_path = TEST_CONFIG_PATH
	
	# 等待一帧以确保配置管理器初始化完成
	await get_tree().process_frame

func after_each():
	if FileAccess.file_exists(TEST_CONFIG_PATH):
		DirAccess.remove_absolute(TEST_CONFIG_PATH)
	await get_tree().process_frame

func test_save_load_config():
	var test_completed := false
	
	# 设置配置值
	_config_manager.set_value("graphics", "resolution", TEST_CONFIG_DATA.graphics.resolution)
	_config_manager.set_value("graphics", "fullscreen", TEST_CONFIG_DATA.graphics.fullscreen)
	_config_manager.set_value("audio", "master_volume", TEST_CONFIG_DATA.audio.master_volume)
	_config_manager.set_value("gameplay", "difficulty", TEST_CONFIG_DATA.gameplay.difficulty)
	
	# 保存配置
	_config_manager.save_config(func(success: bool):
		assert_true(success, "保存配置应该成功")
		
		# 加载并验证配置
		_config_manager.load_config(func(load_success: bool):
			assert_true(load_success, "加载配置应该成功")
			
			var resolution = _config_manager.get_value("graphics", "resolution")
			if resolution is String:
				resolution = str_to_var(resolution)
			assert_eq(resolution, TEST_CONFIG_DATA.graphics.resolution)
			
			assert_eq(_config_manager.get_value("graphics", "fullscreen"), TEST_CONFIG_DATA.graphics.fullscreen)
			assert_eq(_config_manager.get_value("audio", "master_volume"), TEST_CONFIG_DATA.audio.master_volume)
			assert_eq(_config_manager.get_value("gameplay", "difficulty"), TEST_CONFIG_DATA.gameplay.difficulty)
			test_completed = true
		)
	)
	
	await wait_for_test_completion(test_completed)

func test_reset_config():
	var test_completed := false
	
	# 设置一些非默认值
	_config_manager.set_value("graphics", "resolution", Vector2(800, 600))
	_config_manager.set_value("audio", "master_volume", 0.5)
	
	# 重置配置
	_config_manager.reset_config(func(success: bool):
		assert_true(success, "重置配置应该成功")
		
		# 验证值已重置为默认值
		var default_config = CoreSystem.ConfigManager.DefaultConfig.get_default_config()
		var resolution = _config_manager.get_value("graphics", "resolution")
		if resolution is String:
			resolution = str_to_var(resolution)
		assert_eq(resolution, default_config.graphics.resolution)
		
		assert_eq(_config_manager.get_value("audio", "master_volume"), default_config.audio.master_volume)
		test_completed = true
	)
	
	await wait_for_test_completion(test_completed)

func test_auto_save():
	var test_completed := false
	
	# 启用自动保存
	_config_manager.auto_save = true
	
	# 修改配置
	_config_manager.set_value("graphics", "fullscreen", true)
	_config_manager.set_value("audio", "master_volume", 0.7)
	
	# 等待自动保存
	await get_tree().create_timer(0.2).timeout
	
	# 验证文件已创建
	assert_true(FileAccess.file_exists(TEST_CONFIG_PATH))
	
	# 加载并验证值
	_config_manager.load_config(func(success: bool):
		assert_true(success, "加载配置应该成功")
		assert_eq(_config_manager.get_value("graphics", "fullscreen"), true)
		assert_eq(_config_manager.get_value("audio", "master_volume"), 0.7)
		test_completed = true
	)
	
	await wait_for_test_completion(test_completed)

func wait_for_test_completion(completed: bool) -> void:
	var start_time = Time.get_ticks_msec()
	var timeout = 1000  # 1秒超时
	
	while not completed:
		if Time.get_ticks_msec() - start_time > timeout:
			fail_test("测试超时")
			break
		await get_tree().process_frame
