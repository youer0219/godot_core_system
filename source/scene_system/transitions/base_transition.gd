@tool
extends Resource
class_name BaseTransition

## 转场效果基类
## 所有自定义转场效果都应该继承这个类

## 转场矩形
var _transition_rect: ColorRect

## 初始化转场效果
## @param transition_rect 转场矩形
func init(transition_rect: ColorRect) -> void:
	_transition_rect = transition_rect

## 开始转场效果
## @param duration 转场持续时间
func start(duration: float) -> void:
	_reset_state()
	await _do_start(duration)

## 结束转场效果
## @param duration 转场持续时间
func end(duration: float) -> void:
	await _do_end(duration)
	_reset_state()

## 重置状态
## 在开始和结束转场时都会调用
func _reset_state() -> void:
	if not _transition_rect:
		return
	_transition_rect.position = Vector2.ZERO
	_transition_rect.color.a = 0.0

## 执行开始转场
## 子类必须实现这个方法
## @param duration 转场持续时间
func _do_start(_duration: float) -> void:
	push_error("BaseTransition._do_start() not implemented!")
	pass

## 执行结束转场
## 子类必须实现这个方法
## @param duration 转场持续时间
func _do_end(_duration: float) -> void:
	push_error("BaseTransition._do_end() not implemented!")
	pass
