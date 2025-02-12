extends "res://addons/godot_core_system/source/manager_base.gd"

## 实体管理器
## 负责管理实体的生命周期和资源加载

## 实体加载完成信号
signal entity_loaded(entity_id: StringName, entity: Node)
signal entity_unloaded(entity_id: StringName)
## 实体销毁信号
signal entity_created(entity_id: StringName, entity: Node)
signal entity_destroyed(entity_id: StringName, entity: Node)

## 实体资源缓存
var _entity_resource_cache: Dictionary[StringName, PackedScene] = {}
## 实体ID路径映射
var _entity_path_map: Dictionary[StringName, String] = {}

var _resource_manager : CoreSystem.ResourceManager:
	get:
		return CoreSystem.resource_manager

func _ready() -> void:
	_resource_manager.resource_loaded.connect(
		func(resource_path: String, resource: Resource):
			if resource is PackedScene:
				var entity_id := _entity_path_map.find_key(resource_path)
				if not entity_id:
					return
				if _entity_resource_cache.has(entity_id):
					return
				_entity_resource_cache[entity_id] = resource
				entity_loaded.emit(entity_id, resource)
	)
	_resource_manager.resource_unloaded.connect(
		func(resource_path: String):
			var entity_id: StringName = _entity_path_map.find_key(resource_path)
			if not entity_id:
				return
			_entity_resource_cache.erase(entity_id)
			entity_unloaded.emit(entity_id)
	)

## 获取实体场景
func get_entity_scene(entity_id: StringName) -> PackedScene:
	return _entity_resource_cache.get(entity_id)

## 加载实体
## [param entity_id] 实体ID
## [param scene_path] 场景路径
## [param load_mode] 加载模式
## [return] 加载的实体
func load_entity(entity_id: StringName, scene_path: String, 
		load_mode: CoreSystem.ResourceManager.LOAD_MODE = CoreSystem.ResourceManager.LOAD_MODE.IMMEDIATE) -> PackedScene:
	if _entity_resource_cache.has(entity_id):
		push_warning("实体已存在: %s" % entity_id)
		return _entity_resource_cache[entity_id]

	_entity_path_map[entity_id] = scene_path
	var scene: PackedScene = _resource_manager.load_resource(scene_path, load_mode)
	if not scene:
		# push_error("无法加载实体场景: %s" % scene_path)
		return null
		
	_entity_resource_cache[entity_id] = scene
	entity_loaded.emit(entity_id, scene)
	return scene

## 卸载实体
## [param entity_id] 实体ID
func unload_entity(entity_id: StringName) -> void:
	if not _entity_resource_cache.has(entity_id):
		push_warning("实体不存在: %s" % entity_id)
		return
	_resource_manager.unload_resource(_entity_path_map[entity_id])

## 创建实体
## [param entity_id] 实体ID
## [param parent] 父节点
func create_entity(entity_id: StringName, entity_config: Resource, parent : Node = null) -> Node:
	var instance : Node =  _resource_manager.get_instance(_entity_path_map[entity_id])
	if not instance:
		instance = get_entity_scene(entity_id).instantiate()
	
	if not instance or not instance is Node:
		push_error("实体实例不是 Node 类型: %s" % entity_id)
		return
	
	if instance.has_method("initialize"):
		init_entity(instance, entity_config)

	if parent:
		parent.add_child(instance)
	
	entity_created.emit(entity_id, instance)
	return instance

## 初始化实体
## [param entity_id] 实体ID
## [param instance] 要初始化的实体
func init_entity(instance : Node, entity_config: Resource) -> void:
	if not is_entity(instance):
		push_error("实体不是 Entity 类型: %s" % instance)
		return
	
	if not instance.has_method("initialize"):
		# push_error("实体没有 initialize 方法: %s" % instance)
		return
	for component in instance.components:
		if is_component(component):
			initialize_component(component, entity_config)
	instance.initialize(entity_config)

## 更新实体
## [param entity_id] 实体ID
## [param instance] 要更新的实体
func update_entity(instance : Node, data: Dictionary = {}) -> void:
	if not is_entity(instance):
		push_error("实体不是 Entity 类型: %s" % instance)
		return
	for component in instance.components:
		if is_component(component):
			update_component(component, data)
	if instance.has_method("update"):
		instance.update(data)

## 销毁实体
## [param entity_id] 实体ID
## [param instance] 要销毁的实体
func destroy_entity(entity_id: StringName, instance : Node) -> void:
	if not is_entity(instance):
		push_error("实体不是 Entity 类型: %s" % instance)
		return
	for component in instance.components:
		if is_component(component):
			remove_component(instance, component)
	if instance.has_method("destroy"):
		instance.destroy()
	_resource_manager.recycle_instance(_entity_path_map[entity_id], instance)
	entity_destroyed.emit(entity_id, instance)

## 清理所有实体
func clear_entities() -> void:
	for entity_id in _entity_resource_cache.keys():
		_resource_manager.clear_instance_pool(_entity_path_map[entity_id])

## 是否为实体
static func is_entity(node : Node) -> bool:
	if "components" in node and node.components is Dictionary:
		return true
	return false

## 添加组件
## [param component_id] 组件ID
## [param component] 要添加的组件
func add_component(entity: Node, component: Object) -> bool:
	if not is_component(component):
		push_error("不是合法组件: %s, 无法添加" % component)
		return false
	if not is_entity(entity):
		push_error("不是合法实体: %s, 无法添加组件" % entity)
		return false
	entity.components[component.component_id] = component
	return true

## 获取组件
## [param entity] 实体
## [param component_id] 组件ID
## [return] 组件实例
func get_component(entity: Node, component_id: StringName) -> Object:
	if not is_entity(entity):
		push_error("不是合法实体: %s, 无法获取组件" % entity)
		return null
	return entity.components.get(component_id)

## 初始化组件
## [param component] 组件
## [param data] 初始化数据
func initialize_component(component: Object, entity_config: Resource) -> void:
	if not is_component(component):
		push_error("不是合法组件: %s, 无法初始化" % component)
		return
	if not component.has_method("initialize"):
		# push_error("组件 %s 没有 initialize 方法" % component)
		return
	component.initialize(entity_config)

## 更新组件
## [param component] 组件
## [param data] 更新数据
func update_component(component: Object, data: Dictionary = {}) -> void:
	if not is_component(component):
		push_error("不是合法组件: %s, 无法更新" % component)
		return
	if not component.has_method("update_data"):
		# push_error("组件 %s 没有 update_data 方法" % component)
		return
	component.update_data(data)

## 移除组件
## [param entity] 实体
## [param component_id] 组件ID
func remove_component(entity: Node, component_id: StringName) -> void:
	if not is_entity(entity):
		push_error("不是合法实体: %s, 无法移除组件" % entity)
		return
	var component : Object = get_component(entity, component_id)
	if not is_component(component):
		push_error("不是合法组件: %s, 无法移除" % component)
		return
	if not component.has_method("cleanup"):
		# push_error("组件 %s 没有 cleanup 方法" % component)
		return
	component.cleanup()
	entity.components.erase(component_id)

## 是否是组件
## [param node] 节点
## [return] 是否是组件
static func is_component(node : Object) -> bool:
	if "component_id" in node and node.component_id is StringName:
		return true
	return false