extends GutTest

const TEST_SAVE_DIR := "user://test_saves/"
const TEST_SAVE_NAME := "test_save"
const TEST_SAVE_DATA := {
	"player": {
		"position": Vector2(100, 200),
		"health": 100,
		"inventory": ["sword", "shield", "potion"]
	},
	"world": {
		"level": 1,
		"time": 3600,
		"completed_quests": ["quest1", "quest2"]
	}
}

var _test_state: CoreSystem.GameStateData

func before_each():
	# 确保测试目录存在
	if not DirAccess.dir_exists_absolute(TEST_SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(TEST_SAVE_DIR)
	
	# 设置存档目录
	ProjectSettings.set_setting("core_system/save_system/save_directory", TEST_SAVE_DIR)
	
	# 创建测试数据
	_test_state = CoreSystem.GameStateData.new(TEST_SAVE_NAME)
	_test_state.set_data("player", TEST_SAVE_DATA.player)
	_test_state.set_data("world", TEST_SAVE_DATA.world)
	
	# 等待一帧以确保设置生效
	await get_tree().process_frame

func after_each():
	_test_state = null
	
	# 清理测试文件
	var dir := DirAccess.open(TEST_SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	# 删除测试目录
	if DirAccess.dir_exists_absolute(TEST_SAVE_DIR):
		DirAccess.remove_absolute(TEST_SAVE_DIR)
	
	await get_tree().process_frame

func test_create_load_save():
	var test_completed := false
	var save_manager = CoreSystem.save_manager
	
	# 创建存档
	save_manager.create_save(TEST_SAVE_NAME, func(success: bool):
		assert_true(success, "创建存档应该成功")
		
		# 等待文件写入完成
		await get_tree().create_timer(0.1).timeout
		
		# 加载并验证存档
		save_manager.load_save(TEST_SAVE_NAME, func(load_success: bool):
			assert_true(load_success, "加载存档应该成功")
			var current_save = save_manager.get_current_save()
			assert_not_null(current_save, "当前存档不应为空")
			assert_eq(current_save.metadata.save_name, TEST_SAVE_NAME)
			test_completed = true
		)
	)
	
	await wait_for_test_completion(test_completed)

func test_delete_save():
	var test_completed := false
	var save_manager = CoreSystem.save_manager
	
	# 先创建存档
	save_manager.create_save(TEST_SAVE_NAME, func(success: bool):
		assert_true(success)
		
		# 等待文件写入完成
		await get_tree().create_timer(0.1).timeout
		
		# 删除存档
		save_manager.delete_save(TEST_SAVE_NAME, func(delete_success: bool):
			assert_true(delete_success, "删除存档应该成功")
			var save_path = TEST_SAVE_DIR.path_join(TEST_SAVE_NAME + "." + save_manager.save_extension)
			assert_false(FileAccess.file_exists(save_path), "存档文件应该被删除")
			test_completed = true
		)
	)
	
	await wait_for_test_completion(test_completed)

func test_save_list():
	var test_completed := false
	var save_manager = CoreSystem.save_manager
	var saves_created := 0
	var save_names = ["save1", "save2", "save3"]
	
	# 创建多个存档
	for save_name in save_names:
		save_manager.create_save(save_name, func(success: bool):
			assert_true(success)
			saves_created += 1
			
			if saves_created == save_names.size():
				# 等待所有文件写入完成
				await get_tree().create_timer(0.1).timeout
				
				# 获取并验证存档列表
				save_manager.get_save_list(func(saves: Array):
					assert_eq(saves.size(), save_names.size(), "应该列出所有存档")
					for name in save_names:
						assert_true(name in saves, "存档 %s 应该在列表中" % name)
					test_completed = true
				)
		)
	
	await wait_for_test_completion(test_completed)

func test_auto_save():
	var test_completed := false
	var save_manager = CoreSystem.save_manager
	
	# 启用自动保存
	ProjectSettings.set_setting("core_system/save_system/auto_save_enabled", true)
	ProjectSettings.set_setting("core_system/save_system/auto_save_interval", 0.2)
	
	# 创建初始存档
	save_manager.create_save(TEST_SAVE_NAME, func(success: bool):
		assert_true(success)
		
		# 等待自动存档
		await get_tree().create_timer(0.3).timeout
		
		# 验证自动存档是否创建
		save_manager.get_save_list(func(saves: Array):
			var auto_saves = saves.filter(func(save_name: String): 
				return save_name.begins_with("auto_save_")
			)
			assert_gt(auto_saves.size(), 0, "应该创建自动存档")
			test_completed = true
		)
	)
	
	await wait_for_test_completion(test_completed)

func test_max_auto_saves():
	var test_completed := false
	var save_manager = CoreSystem.save_manager
	var auto_saves_created := 0
	
	# 设置最大自动存档数量
	ProjectSettings.set_setting("core_system/save_system/max_auto_saves", 2)
	
	# 创建多个自动存档
	for i in range(4):
		save_manager.create_auto_save()
		auto_saves_created += 1
		
		if auto_saves_created == 4:
			# 等待所有文件操作完成
			await get_tree().create_timer(0.3).timeout
			
			# 验证自动存档数量
			save_manager.get_save_list(func(saves: Array):
				var auto_saves = saves.filter(func(save_name: String): 
					return save_name.begins_with("auto_save_")
				)
				assert_eq(auto_saves.size(), 2, "应该只保留指定数量的自动存档")
				test_completed = true
			)
	
	await wait_for_test_completion(test_completed)

func wait_for_test_completion(completed: bool) -> void:
	var start_time = Time.get_ticks_msec()
	var timeout = 2000  # 2秒超时
	
	while not completed:
		if Time.get_ticks_msec() - start_time > timeout:
			fail_test("测试超时")
			break
		await get_tree().process_frame
