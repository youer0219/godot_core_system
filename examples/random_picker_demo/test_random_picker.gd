extends Node

# 测试配置
const LARGE_DATA_SIZE := 5000
const STRESS_TEST_COUNT := 1000

var _random_pool : RefCounted

var default_items:Array = [
			["sword", 10],
			["shield", 8],
			["potion", 15],
			["key", 1],
			{"data": "gem", "weight": 5}
		]

func _ready() -> void:
	_test_basic_functionality()
	await get_tree().create_timer(1.0).timeout
	_test_large_data()
	await get_tree().create_timer(1.0).timeout
	_test_dynamic_changes()

# 基础功能测试
func _test_basic_functionality() -> void:
	print("\n=== 开始基础功能测试 ===")
	_random_pool = _create_test_pool(default_items)
	
	# 测试初始状态
	assert(_random_pool.get_remaining_count() == 5, "初始数量校验失败")
	print("✓ 初始物品数量正确")
	
	# 测试存在性检查
	assert(_random_pool.has_item("sword"), "存在性检查失败")
	print("✓ 存在性检查正常")
	
	# 测试单次抽取
	var first_item = _random_pool.get_random_item()
	print("抽取到(不移出池):", first_item)
	assert(first_item in ["sword","shield","potion","key","gem"], "无效物品")
	print("✓ 单次抽取正常")
	
	# 测试带删除的抽取
	var removed_item = _random_pool.get_random_item(true)
	print("抽取到(移出池):", removed_item)
	assert(_random_pool.get_remaining_count() == 4, "删除后计数错误")
	print("✓ 删除抽取后数量正确")
	
	# 测试批量删除
	var remove_count = _random_pool.remove_items(["invalid_item02", "invalid_item"])
	assert(remove_count == 0, "批量删除计数错误")
	assert(_random_pool.get_remaining_count() == 4, "删除后数量错误")
	print("✓ 批量删除功能正常")
	
	# 测试清空
	_random_pool.clear()
	assert(_random_pool.is_empty(), "清空失败")
	print("✓ 清空功能正常")
	
	print("=== 基础测试通过 ===")

# 大数据压力测试
func _test_large_data() -> void:
	print("\n=== 开始大数据测试 ===")
	var start_time := Time.get_ticks_msec()
	
	# 生成测试数据
	var big_data := []
	for i in LARGE_DATA_SIZE:
		big_data.append({"data": "item_%d" % i, "weight": randf_range(0.1, 10.0)})
	
	# 创建池
	_random_pool = _create_test_pool(big_data)
	var create_time := Time.get_ticks_msec() - start_time
	print("创建 %d 项耗时: %.2f秒" % [LARGE_DATA_SIZE, create_time/1000.0])
	
	# 多次随机测试
	start_time = Time.get_ticks_msec()
	for i in STRESS_TEST_COUNT:
		_random_pool.get_random_item()
	var query_time := Time.get_ticks_msec() - start_time
	print("%d 次抽取耗时: %.2f秒 (平均 %.2fms/次)" % [
		STRESS_TEST_COUNT, 
		query_time/1000.0,
		float(query_time)/STRESS_TEST_COUNT
	])
	
	# 验证分布（粗略检查）
	var distribution := {}
	for i in 1000:
		var item = _random_pool.get_random_item()
		distribution[item] = distribution.get(item, 0) + 1
	
	print("分布示例（前5项）:")
	var count := 0
	for k in distribution:
		print("%s: %d 次" % [k, distribution[k]])
		count += 1
		if count >= 5:
			break
	
	print("=== 大数据测试完成 ===")

# 动态变动测试
func _test_dynamic_changes() -> void:
	print("\n=== 开始动态变动测试 ===")
	_random_pool = _create_test_pool(default_items)
	
	# 连接信号
	_random_pool.item_picked.connect(func(item): print("抽到:", item))
	_random_pool.pool_emptied.connect(func(): print("★ 池子清空!"))
	
	# 动态添加测试
	print("-- 动态添加测试 --")
	_random_pool.add_item("dragon_sword", 5.0)
	assert(_random_pool.get_remaining_count() == 6, "动态添加失败")
	print("✓ 动态添加成功")
	
	# 批量添加测试
	var added = _random_pool.add_items([
		["scroll", 2.5],
		{"data": "ring", "weight": 1.5}
	])
	assert(added == 2, "批量添加失败")
	print("✓ 批量添加成功")
	
	# 动态删除测试
	print("-- 动态删除测试 --")
	while not _random_pool.is_empty():
		_random_pool.get_random_item(true)
		print("剩余:", _random_pool.get_remaining_count())
	
	print("=== 动态测试完成 ===")

# 创建测试池
func _create_test_pool(items:Array) -> RefCounted: 
	return CoreSystem.RandomPicker.new(items)
