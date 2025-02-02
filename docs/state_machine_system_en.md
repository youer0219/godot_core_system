# Hierarchical State Machine System

## Overview
The Hierarchical State Machine System provides a flexible and extensible state management solution. The system supports state nesting, state history, event handling, and variable sharing, making it particularly suitable for game AI, UI interactions, and game flow control.

## Core Concepts

### State
- Represents a specific behavior or condition
- Can have entry/exit logic
- Supports update (per frame) and physics update (fixed rate)
- Can handle events
- Can access and modify shared variables

### State Machine
- Manages transitions between multiple states
- Maintains current active state
- Handles state transition logic
- Supports state history
- Manages shared variables

### Hierarchical Features
- States can contain sub-state machines
- Child states can access parent state variables
- Events can propagate through state hierarchy
- Supports state inheritance and reuse

## Usage Examples

### 1. Basic State Machine
```gdscript
# Create a simple state
class_name IdleState extends BaseState
func enter(msg := {}):
    super.enter(msg)
    print("Entering idle state")

func update(delta: float):
    if agent.is_moving:
        transition_to("move")

# Use the state machine
var state_machine = BaseStateMachine.new()
state_machine.add_state("idle", IdleState)
state_machine.add_state("move", MoveState)
state_machine.transition_to("idle")
```

### 2. Hierarchical State Machine
```gdscript
# Create a state with sub-state machine
class_name CombatState extends BaseState
var sub_state_machine: BaseStateMachine

func _init():
    sub_state_machine = BaseStateMachine.new(self)
    sub_state_machine.add_state("attack", AttackState)
    sub_state_machine.add_state("defend", DefendState)

func enter(msg := {}):
    super.enter(msg)
    sub_state_machine.transition_to("attack")

# Use in main state machine
main_state_machine.add_state("combat", CombatState)
main_state_machine.add_state("explore", ExploreState)
```

### 3. Event Handling
```gdscript
# Handle events in state
class_name PlayerState extends BaseState
func _on_damage_taken(amount: int):
    if amount > 50:
        transition_to("hurt")
    elif parent_state:
        parent_state.handle_event("damage_taken", [amount])

# Trigger event
state_machine.handle_event("damage_taken", [30])
```

## Best Practices

1. State Organization
   - Organize related states in the same state machine
   - Use meaningful state names
   - Keep state logic simple and clear

2. State Transitions
   - Switch states at appropriate times
   - Use msg parameter to pass necessary transition information
   - Make good use of state history feature

3. Variable Management
   - Use shared variables appropriately
   - Pay attention to variable scope
   - Clean up unnecessary variables

4. Event Handling
   - Use event propagation mechanism appropriately
   - Avoid event handling loops
   - Keep event parameters simple and clear

## Important Notes

1. State Machine Initialization
   - Ensure proper initialization before use
   - Set necessary initial states
   - Configure state machine agent correctly

2. Performance Considerations
   - Avoid intensive calculations in update
   - Use physics update appropriately
   - Clean up unnecessary states and variables

3. Debugging
   - Use state machine signals for debugging
   - Monitor state transitions and event propagation
   - Check variable changes
