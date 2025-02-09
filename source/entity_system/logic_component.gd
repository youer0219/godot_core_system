extends Resource
class_name LogicComponent

## 组件基类
## 提供组件的基本功能和生命周期管理

## 组件ID
var component_id: StringName:
	get:
		return component_id
	set(value):
		component_id = value

## 组件数据
var component_data: Dictionary = {}
## 所属实体
var owner : EntityLogic

## 初始化组件
func initialize() -> void:
	_initialize()

## 更新组件数据
## [param data] 组件数据
func update_data(data: Dictionary) -> void:
	component_data.merge(data, true)
	_on_data_updated(data)

## 清理组件
func cleanup() -> void:
	_cleanup()
	component_data.clear()

## 子类重写的初始化方法
func _initialize() -> void:
	pass

## 子类重写的数据更新回调
func _on_data_updated(data: Dictionary) -> void:
	pass

## 子类重写的清理方法
func _cleanup() -> void:
	pass
