extends RefCounted

## 分帧执行器
## 用于将耗时操作分散到多帧执行，避免卡顿
## 使用示例:
## ```gdscript
## var splitter = FrameSplitter.new()
## # 处理数组
## await splitter.process_array(items, func(item): 
##     # 处理单个item的逻辑
##     print(item)
## )
## # 处理范围
## await splitter.process_range(0, 1000, func(i): 
##     # 处理数字i的逻辑
##     print(i)
## )
## ```

signal progress_changed(progress: float)  ## 进度变化信号 0-1
signal completed  ## 执行完成信号

## 每帧处理的默认数量
var items_pre_frame = 100
## 每帧默认最大执行时间（毫秒）
var max_ms_pre_frame = 8.0  # 假设目标60FPS，留出足够余量

func _init(p_items_per_frame: int = items_pre_frame, p_max_ms_per_frame: float = max_ms_pre_frame) -> void:
	items_pre_frame = p_items_per_frame
	max_ms_pre_frame = p_max_ms_per_frame

## 处理数组
## [param items] 要处理的数组
## [param process_func] 处理单个元素的函数，接收一个参数
## [param max_ms_per_frame] 每帧最大执行时间（毫秒），默认8ms
## [param initial_items_per_frame] 初始每帧处理数量，默认100（会根据实际执行时间动态调整）
func process_array(items: Array, process_func: Callable, max_ms_per_frame: float = max_ms_pre_frame, initial_items_per_frame: int = items_pre_frame) -> void:
	var total_items = items.size()
	var processed_items = 0
	var items_per_frame = initial_items_per_frame
	
	while processed_items < total_items:
		var frame_start_time = Time.get_ticks_msec()
		var frame_items = 0
		
		# 处理项目直到达到时间限制
		while processed_items < total_items and frame_items < items_per_frame:
			process_func.call(items[processed_items])
			processed_items += 1
			frame_items += 1
			
			# 检查是否超过时间限制
			if (Time.get_ticks_msec() - frame_start_time) >= max_ms_per_frame:
				break
		
		# 动态调整每帧处理数量
		var frame_time = Time.get_ticks_msec() - frame_start_time
		if frame_time > 0:  # 避免除以零
			if frame_time > max_ms_per_frame:
				# 如果执行时间过长，减少每帧处理数量
				items_per_frame = max(1, int(float(frame_items) * max_ms_per_frame / frame_time))
			elif frame_time < max_ms_per_frame * 0.8:  # 留出20%余量
				# 如果执行时间充裕，适当增加每帧处理数量
				items_per_frame = min(items_per_frame * 2, items_pre_frame)
		
		progress_changed.emit(float(processed_items) / total_items)
		await CoreSystem.get_tree().process_frame
	
	completed.emit()

## 处理数字范围
## [param start] 起始数字（包含）
## [param end] 结束数字（不包含）
## [param process_func] 处理单个数字的函数，接收一个参数
## [param max_ms_per_frame] 每帧最大执行时间（毫秒），默认8ms
## [param initial_items_per_frame] 初始每帧处理数量，默认100（会根据实际执行时间动态调整）
func process_range(start: int, end: int, process_func: Callable, max_ms_per_frame: float = max_ms_pre_frame, initial_items_per_frame: int = items_pre_frame) -> void:
	var total_items = end - start
	var processed_items = 0
	var items_per_frame = initial_items_per_frame
	
	while processed_items < total_items:
		var frame_start_time = Time.get_ticks_msec()
		var frame_items = 0
		
		# 处理项目直到达到时间限制
		while processed_items < total_items and frame_items < items_per_frame:
			process_func.call(start + processed_items)
			processed_items += 1
			frame_items += 1
			
			# 检查是否超过时间限制
			if (Time.get_ticks_msec() - frame_start_time) >= max_ms_per_frame:
				break
		
		# 动态调整每帧处理数量
		var frame_time = Time.get_ticks_msec() - frame_start_time
		if frame_time > 0:
			if frame_time > max_ms_per_frame:
				items_per_frame = max(1, int(float(frame_items) * max_ms_per_frame / frame_time))
			elif frame_time < max_ms_per_frame * 0.8:
				items_per_frame = min(items_per_frame * 2, items_pre_frame)
		
		progress_changed.emit(float(processed_items) / total_items)
		await CoreSystem.get_tree().process_frame
	
	completed.emit()

## 处理自定义迭代器
## [param iterator] 自定义迭代器对象，必须实现has_next()和next()方法
## [param process_func] 处理单个元素的函数，接收一个参数
## [param total_items] 总项目数（用于进度计算）
## [param max_ms_per_frame] 每帧最大执行时间（毫秒），默认8ms
## [param initial_items_per_frame] 初始每帧处理数量，默认100（会根据实际执行时间动态调整）
func process_iterator(iterator, process_func: Callable, total_items: int, max_ms_per_frame: float = max_ms_pre_frame, initial_items_per_frame: int = items_pre_frame) -> void:
	var processed_items = 0
	var items_per_frame = initial_items_per_frame
	
	while iterator.has_next() and processed_items < total_items:
		var frame_start_time = Time.get_ticks_msec()
		var frame_items = 0
		
		# 处理项目直到达到时间限制
		while iterator.has_next() and processed_items < total_items and frame_items < items_per_frame:
			process_func.call(iterator.next())
			processed_items += 1
			frame_items += 1
			
			# 检查是否超过时间限制
			if (Time.get_ticks_msec() - frame_start_time) >= max_ms_per_frame:
				break
		
		# 动态调整每帧处理数量
		var frame_time = Time.get_ticks_msec() - frame_start_time
		if frame_time > 0:
			if frame_time > max_ms_per_frame:
				items_per_frame = max(1, int(float(frame_items) * max_ms_per_frame / frame_time))
			elif frame_time < max_ms_per_frame * 0.8:
				items_per_frame = min(items_per_frame * 2, items_pre_frame)
		
		progress_changed.emit(float(processed_items) / total_items)
		await CoreSystem.get_tree().process_frame
	
	completed.emit()

## 自定义执行
## [param total_work] 总工作量
## [param work_func] 执行工作的函数，接收起始索引和结束索引两个参数
## [param max_ms_per_frame] 每帧最大执行时间（毫秒），默认8ms
## [param initial_work_per_frame] 初始每帧处理工作量，默认100（会根据实际执行时间动态调整）
func process_custom(total_work: int, work_func: Callable, max_ms_per_frame: float = max_ms_pre_frame, initial_work_per_frame: int = items_pre_frame) -> void:
	var processed_work = 0
	var work_per_frame = initial_work_per_frame
	
	while processed_work < total_work:
		var frame_start_time = Time.get_ticks_msec()
		
		# 计算这一帧要处理的工作量
		var frame_work = min(work_per_frame, total_work - processed_work)
		
		# 执行这一帧的工作
		work_func.call(processed_work, processed_work + frame_work)
		
		# 计算实际执行时间
		var frame_time = Time.get_ticks_msec() - frame_start_time
		if frame_time > 0:
			if frame_time > max_ms_per_frame:
				work_per_frame = max(1, int(float(frame_work) * max_ms_per_frame / frame_time))
			elif frame_time < max_ms_per_frame * 0.8:
				work_per_frame = min(work_per_frame * 2, items_pre_frame)
		
		processed_work += frame_work
		progress_changed.emit(float(processed_work) / total_work)
		
		await CoreSystem.get_tree().process_frame
	
	completed.emit()
