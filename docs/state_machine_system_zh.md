# 分层状态机系统

## 概述
分层状态机系统提供了一个灵活、可扩展的状态管理解决方案。系统支持状态嵌套、状态历史记录、事件处理和变量共享等特性，特别适合用于游戏AI、UI交互和游戏流程控制等场景。

## 核心概念

### 状态（State）
- 代表一个具体的行为或状态
- 可以有自己的进入/退出逻辑
- 支持更新（每帧）和物理更新（固定帧率）
- 可以处理事件
- 可以访问和修改共享变量

### 状态机（StateMachine）
- 管理多个状态之间的转换
- 维护当前活动状态
- 处理状态切换逻辑
- 支持状态历史记录
- 管理共享变量

### 分层特性
- 状态可以包含子状态机
- 子状态可以访问父状态的变量
- 事件可以在状态层级间传播
- 支持状态的继承和复用

## 使用示例

### 1. 基础状态机
```gdscript
# 创建一个简单的状态
class_name IdleState extends BaseState
func enter(msg := {}):
    super.enter(msg)
    print("进入空闲状态")

func update(delta: float):
    if agent.is_moving:
        transition_to("move")

# 使用状态机
var state_machine = BaseStateMachine.new()
state_machine.add_state("idle", IdleState)
state_machine.add_state("move", MoveState)
state_machine.transition_to("idle")
```

### 2. 分层状态机
```gdscript
# 创建一个包含子状态机的状态
class_name CombatState extends BaseState
var sub_state_machine: BaseStateMachine

func _init():
    sub_state_machine = BaseStateMachine.new(self)
    sub_state_machine.add_state("attack", AttackState)
    sub_state_machine.add_state("defend", DefendState)

func enter(msg := {}):
    super.enter(msg)
    sub_state_machine.transition_to("attack")

# 在主状态机中使用
main_state_machine.add_state("combat", CombatState)
main_state_machine.add_state("explore", ExploreState)
```

### 3. 事件处理
```gdscript
# 在状态中处理事件
class_name PlayerState extends BaseState
func _on_damage_taken(amount: int):
    if amount > 50:
        transition_to("hurt")
    elif parent_state:
        parent_state.handle_event("damage_taken", [amount])

# 触发事件
state_machine.handle_event("damage_taken", [30])
```

## 最佳实践

1. 状态组织
   - 将相关状态组织在同一个状态机中
   - 使用有意义的状态名称
   - 保持状态逻辑简单明确

2. 状态切换
   - 在适当的时机切换状态
   - 使用msg参数传递必要的切换信息
   - 善用状态历史记录功能

3. 变量管理
   - 合理使用共享变量
   - 注意变量的作用域
   - 及时清理不需要的变量

4. 事件处理
   - 合理使用事件传播机制
   - 避免事件处理循环
   - 保持事件参数简单明确

## 注意事项

1. 状态机初始化
   - 确保在使用前正确初始化状态机
   - 设置必要的初始状态
   - 正确配置状态机的代理对象

2. 性能考虑
   - 避免在update中进行密集计算
   - 合理使用物理更新
   - 及时清理不需要的状态和变量

3. 调试
   - 使用状态机提供的信号进行调试
   - 监控状态切换和事件传播
   - 检查变量的变化
