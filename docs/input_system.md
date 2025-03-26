# Input System

The Input System provides a flexible and powerful way to handle user input in your game, supporting virtual actions and axis mappings.

## Features

- 🎮 **Virtual Actions**: Define and manage custom input actions
- 🕹️ **Axis Mapping**: Create virtual axes from action combinations
- 📊 **Input States**: Track pressed, just pressed, and just released states
- 🎯 **Event Handling**: Comprehensive input event processing
- 🔄 **Dynamic Registration**: Register and clear input mappings at runtime
- 📈 **Configuration System**: Manage input settings and device mappings

## Core Components

### InputManager

Central manager for all input operations:
- Virtual action management
- Axis mapping
- Input state tracking
- Configuration management

```gdscript
# Register a virtual action
input_manager.register_virtual_action(
    "jump",                 # Action name
    [jump_event]           # Key combination
)

# Register an axis
input_manager.register_axis(
    "movement",            # Axis name
    "move_right",         # Positive X
    "move_left",          # Negative X
    "move_down",          # Positive Y
    "move_up"             # Negative Y
)

# Setup input configuration
input_manager.setup_config(CoreSystem.config_manager)
```

## API Reference

### InputManager

#### Signals

```gdscript
# Emitted when an action is triggered
signal action_triggered(action_name: String, event: InputEvent)

# Emitted when an axis value changes
signal axis_changed(axis_name: String, value: Vector2)
```

#### Methods

##### Virtual Actions

```gdscript
# Register a virtual action
func register_virtual_action(
    action_name: String,       # Action name
    key_combination: Array     # Key combination
) -> void

# Check if action is pressed
func is_action_pressed(action_name: String) -> bool

# Check if action was just pressed
func is_action_just_pressed(action_name: String) -> bool

# Check if action was just released
func is_action_just_released(action_name: String) -> bool
```

##### Axis Mapping

```gdscript
# Register a virtual axis
func register_axis(
    axis_name: String,        # Axis name
    positive_x: String = "",  # Positive X action
    negative_x: String = "",  # Negative X action
    positive_y: String = "",  # Positive Y action
    negative_y: String = ""   # Negative Y action
) -> void

# Get axis value
func get_axis_value(axis_name: String) -> Vector2
```

##### System Management

```gdscript
# Clear all virtual inputs
func clear_virtual_inputs() -> void

# Setup input configuration
func setup_config(config_manager: ConfigManager) -> void
```

## Configuration System

The input system uses a dedicated configuration system that separates the concerns of input configuration management from the core input functionality.

### Components

- `InputConfig`: Core configuration data structure
- `InputConfigAdapter`: Bridge between ConfigManager and InputConfig

### Configuration Structure

```gdscript
# Default configuration
const DEFAULT_CONFIG = {
    "action_mappings": {},  # Action to input event mappings
    "axis_mappings": {},    # Virtual axis mappings
    "device_mappings": {},  # Device-specific mappings
    "input_settings": {     # General input settings
        "deadzone": 0.2,
        "axis_sensitivity": 1.0,
        "vibration_enabled": true,
        "vibration_strength": 1.0
    }
}
```

### Using the Configuration System

```gdscript
# Access input configuration
var config = input_manager._config_adapter.get_input_config()

# Update settings
input_manager._config_adapter.set_deadzone(0.3)
input_manager._config_adapter.set_axis_sensitivity(1.5)

# Save configuration
input_manager.save_config()

# Reset to defaults
input_manager.reset_to_default()
```

## Best Practices

1. Register virtual actions at game startup or scene initialization
2. Use meaningful names for actions and axes
3. Clear virtual inputs when changing game states
4. Handle input events through the input manager instead of directly
5. Use axis mapping for movement and similar continuous inputs
6. Use the configuration system for managing input settings

## Examples

```gdscript
# Setup player input
func _ready():
    # Register movement axis
    input_manager.register_axis(
        "movement",
        "move_right",
        "move_left",
        "move_down",
        "move_up"
    )
    
    # Register jump action
    var jump_event = InputEventKey.new()
    jump_event.keycode = KEY_SPACE
    input_manager.register_virtual_action("jump", [jump_event])

# Handle input in process
func _process(delta):
    # Get movement input
    var movement = input_manager.get_axis_value("movement")
    position += movement * speed * delta
    
    # Check jump input
    if input_manager.is_action_just_pressed("jump"):
        jump()
```

```gdscript
# Update action mapping
func remap_jump_key():
    var event = await get_next_input_event()
    input_manager.update_action_mapping("jump", [
        input_manager.get_event_data(event)
    ])

# Update input settings
func update_settings():
    input_manager._config_adapter.set_deadzone(0.3)
    input_manager._config_adapter.set_axis_sensitivity(1.5)
    input_manager.save_config()

# Reset to default configuration
func reset_settings():
    input_manager.reset_to_default()
