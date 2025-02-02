extends "res://addons/godot_core_system/source/manager_base.gd"

## 场景管理器

# 信号
## 开始加载场景
signal scene_loading_started(scene_path: String)
## 场景加载进度
signal scene_loading_progress(progress: float)
## 场景切换
signal scene_changed(old_scene: Node, new_scene: Node)
## 结束加载场景
signal scene_loading_finished()

## 场景转换效果
enum TransitionEffect {
	NONE,       ## 无转场效果
	FADE,       ## 淡入淡出
	SLIDE,      ## 滑动
	DISSOLVE    ## 溶解
}

# 属性
## 当前场景
var _current_scene: Node = null
## 加载中的场景
var _loading_scene: Node = null
## 预加载的场景
var _preloaded_scenes: Dictionary = {}
## 转场层
var _transition_layer: CanvasLayer
## 转场矩形
var _transition_rect: ColorRect

func _init():
	_setup_transition_layer()

## 预加载场景
## @param scene_path 场景路径
func preload_scene(scene_path: String) -> void:
	if not _preloaded_scenes.has(scene_path):
		var scene_resource = load(scene_path)
		if scene_resource:
			_preloaded_scenes[scene_path] = scene_resource

## 异步切换场景
## @param scene_path 场景路径
## @param effect 转场效果
## @param duration 转场持续时间
## @param callback 切换完成回调
func change_scene_async(scene_path: String, effect: TransitionEffect = TransitionEffect.NONE, 
			duration: float = 0.5, callback: Callable = Callable()) -> void:
	scene_loading_started.emit(scene_path)
	
	# 开始转场效果
	if effect != TransitionEffect.NONE:
		await _start_transition(effect, duration)
	
	# 加载新场景
	var new_scene
	if _preloaded_scenes.has(scene_path):
		new_scene = _preloaded_scenes[scene_path].instantiate()
		scene_loading_progress.emit(1.0)
	else:
		var scene_resource = load(scene_path)
		if scene_resource:
			new_scene = scene_resource.instantiate()
			scene_loading_progress.emit(1.0)
	
	if new_scene:
		var old_scene = _current_scene
		
		# 移除当前场景
		if _current_scene:
			_current_scene.queue_free()
		
		# 添加新场景
		CoreSystem.get_tree().root.add_child(new_scene)
		CoreSystem.get_tree().current_scene = new_scene
		_current_scene = new_scene
		
		scene_changed.emit(old_scene, new_scene)
		
		# 结束转场效果
		if effect != TransitionEffect.NONE:
			await _end_transition(effect, duration)

		# 回调
		if callback.is_valid():
			callback.call()        
		scene_loading_finished.emit()

## 获取当前场景
func get_current_scene() -> Node:
	return _current_scene

## 清除预加载的场景
func clear_preloaded_scenes() -> void:
	_preloaded_scenes.clear()

## 开始转场效果
## @param effect 转场效果
## @param duration 转场持续时间
func _start_transition(effect: TransitionEffect, duration: float) -> void:
	_transition_rect.visible = true
	
	match effect:
		TransitionEffect.FADE:
			# 淡入淡出
			var tween = CoreSystem.create_tween()
			tween.tween_property(_transition_rect, "color:a", 1.0, duration)
			await tween.finished
		
		TransitionEffect.SLIDE:
			# 滑动
			_transition_rect.color.a = 1.0
			_transition_rect.position.x = -_transition_rect.size.x
			var tween = CoreSystem.create_tween()
			tween.tween_property(_transition_rect, "position:x", 0, duration)
			await tween.finished
		
		TransitionEffect.DISSOLVE:
			# 溶解
			#TODO 这里可以添加更复杂的溶解效果
			var tween = CoreSystem.create_tween()
			tween.tween_property(_transition_rect, "color:a", 1.0, duration)
			await tween.finished

## 结束转场效果
## @param effect 转场效果
## @param duration 转场持续时间
func _end_transition(effect: TransitionEffect, duration: float) -> void:
	match effect:
		TransitionEffect.FADE:
			## 淡出
			var tween = CoreSystem.create_tween()
			tween.tween_property(_transition_rect, "color:a", 0.0, duration)
			await tween.finished
		
		TransitionEffect.SLIDE:
			## 滑动
			var tween = CoreSystem.create_tween()
			tween.tween_property(_transition_rect, "position:x", _transition_rect.size.x, duration)
			await tween.finished
		
		TransitionEffect.DISSOLVE:
			## 溶解
			var tween = CoreSystem.create_tween()
			tween.tween_property(_transition_rect, "color:a", 0.0, duration)
			await tween.finished
	
	_transition_rect.visible = false

## 设置转场层
func _setup_transition_layer():
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 128
	CoreSystem.add_child(_transition_layer)
	
	_transition_rect = ColorRect.new()
	_transition_rect.color = Color(0, 0, 0, 0)
	_transition_rect.visible = false
	_transition_layer.add_child(_transition_rect)
	
	CoreSystem.get_tree().root.connect("size_changed", _on_viewport_size_changed)
	_on_viewport_size_changed()

## 设置转场矩形大小
func _on_viewport_size_changed():
	if _transition_rect:
		_transition_rect.size = CoreSystem.get_viewport().get_visible_rect().size
