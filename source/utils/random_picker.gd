extends RefCounted

var _remove_after_pick: bool
var _item_pool: Array[Dictionary]
var _logger : CoreSystem.Logger = CoreSystem.logger

var _alias: Array[int] = []
var _prob: Array[float] = []
var _total_weight: float = 0.0

signal item_picked(item_data: Variant)
signal pool_emptied

func _init(items: Array = []) -> void:
	if items.is_empty():
		return
	add_items(items)

## 添加随机项
func add_item(item_data: Variant, item_weight: float, rebuild: bool = true) -> bool:
	if item_weight <= 0:
		_logger.error("道具权重必须为正数 %s" % str(item_data))
		return false
	for item in _item_pool:
		if item.data == item_data:
			_logger.warning("%s物品已经存在，添加失败！" % str(item_data))
			return false
	_item_pool.append({"data": item_data, "weight": item_weight})
	if rebuild:
		_build_alias_table()
	return true

## 批量添加随机项
func add_items(items: Array) -> int:
	var success_count := 0
	for item in items:
		var data
		var weight
		if item is Array:
			if item.size() < 2:
				_logger.error("物品格式不合法！%s" % str(item))
				continue
			data = item[0]
			weight = float(item[1])
		elif item is Dictionary:
			if not (item.has("data") and item.has("weight")):
				_logger.error("物品格式错误，必须包含 data 和 weight 字段 %s" % str(item))
				continue
			data = item.data
			weight = item.weight
		else:
			_logger.error("无效的物品格式 %s" % str(item))
			continue
		if add_item(data, weight, false):
			success_count += 1
	_build_alias_table()
	return success_count

## 删除指定项
func remove_item(item_data: Variant, rebuild: bool = true) -> bool:
	for i in range(_item_pool.size()):
		if _item_pool[i].data == item_data:
			_item_pool.remove_at(i)
			if rebuild:
				_build_alias_table()
			return true
	_logger.warning("要删除的物品不存在", {"item_data": item_data})
	return false

## 批量删除指定物品
## [param item_datas] 要删除的物品数据数组
## [return] 成功删除的数量
func remove_items(item_datas: Array) -> int:
	var success_count := 0
	# 逐个尝试删除，但不立即重建别名表
	for data in item_datas:
		if remove_item(data, false):
			success_count += 1
	
	# 只要有成功删除的项就重建一次别名表
	if success_count > 0:
		_build_alias_table()
	
	return success_count

## 获取随机项
func get_random_item(should_remove: bool = false) -> Variant:
	if _item_pool.is_empty():
		return null

	var n := _item_pool.size()
	var index := randi() % n
	var r := randf()

	if r >= _prob[index]:
		index = _alias[index]

	var selected_item: Dictionary = _item_pool[index]

	if should_remove:
		_item_pool.remove_at(index)
		_build_alias_table()

	if _item_pool.is_empty():
		pool_emptied.emit()

	item_picked.emit(selected_item.data)
	return selected_item.data

## 清空池子
func clear() -> void:
	_item_pool.clear()
	_build_alias_table()

## 构建别名表和概率表
func _build_alias_table() -> void:
	var n := _item_pool.size()
	_alias.resize(n)
	_prob.resize(n)
	_total_weight = 0.0

	if n == 0:
		return

	for item in _item_pool:
		_total_weight += item.weight

	if _total_weight <= 0:
		_logger.error("总权重必须为正数，无法构建别名表")
		_alias.clear()
		_prob.clear()
		return

	var scaled_weights: Array[float] = []
	scaled_weights.resize(n)
	var over: Array[int] = []
	var under: Array[int] = []

	for i in range(n):
		scaled_weights[i] = (_item_pool[i].weight * n) / _total_weight
		if scaled_weights[i] >= 1.0:
			over.append(i)
		else:
			under.append(i)

	while not under.is_empty() and not over.is_empty():
		var u = under.pop_back()
		var o = over.pop_back()

		_prob[u] = scaled_weights[u]
		_alias[u] = o
		scaled_weights[o] += scaled_weights[u] - 1.0

		if scaled_weights[o] < 1.0:
			under.append(o)
		else:
			over.append(o)

	while not over.is_empty():
		var o = over.pop_back()
		_prob[o] = 1.0
		_alias[o] = o

	while not under.is_empty():
		var u = under.pop_back()
		_prob[u] = 1.0
		_alias[u] = u

## 获取随机项个数
func get_remaining_count() -> int:
	return _item_pool.size()

## 获取所有随机项
func get_all_items() -> Array[Dictionary]:
	return _item_pool.duplicate()

## 是否为空
func is_empty() -> bool:
	return _item_pool.is_empty()

## 检查物品是否存在
## [return] 是否存在
func has_item(item_data: Variant) -> bool:
	for item in _item_pool:
		if item.data == item_data:
			return true
	return false
