# Godot Core System

<div align="center">

[English](README.md) | [简体中文](README_zh.md)

![Godot v4.4](https://img.shields.io/badge/Godot-v4.4-478cbf?logo=godot-engine&logoColor=white)
[![GitHub license](https://img.shields.io/github/license/Liweimin0512/godot_core_system)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/Liweimin0512/godot_core_system)](https://github.com/Liweimin0512/godot_core_system/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/Liweimin0512/godot_core_system)](https://github.com/Liweimin0512/godot_core_system/issues)
[![GitHub forks](https://img.shields.io/github/forks/Liweimin0512/godot_core_system)](https://github.com/Liweimin0512/godot_core_system/network)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

A highly modular and extensible core system framework for Godot 4.4

[Getting Started](#getting-started) •
[Documentation](#documentation) •
[Examples](#examples) •
[Contributing](CONTRIBUTING.md) •
[Support](#support)

</div>

## ✨ Features

- 🎮 **State Machine System**: Flexible and powerful state management for game logic
- 💾 **Serialization System**: Easy-to-use save/load functionality with config management
- 🎵 **Audio System**: Comprehensive audio management with categories and transitions
- 🎯 **Input System**: Unified input handling with action mapping and event management
- 📝 **Logger System**: Detailed logging system with multiple output channels
- 🎨 **Resource System**: Efficient resource loading and management
- 🎬 **Scene System**: Scene transition and management made easy
- 🔧 **Plugin Architecture**: Easy to extend and customize
- 📱 **Project Settings Integration**: Configure all systems through Godot's project settings
- 🛠️ **Development Tools**: Built-in debugging and development tools

## 🚀 Getting Started

### Prerequisites

- Godot Engine 4.4 +
- Basic knowledge of GDScript and Godot Engine

### Installation

1. Download the latest release from the [releases page](https://github.com/Liweimin0512/godot_core_system/releases)
2. Copy the `godot_core_system` folder to your Godot project's `addons` directory
3. Enable the plugin in Godot: Project -> Project Settings -> Plugins -> Godot Core System -> Enable

### Quick Start

```gdscript
extends Node

func _ready():
	# Access managers through CoreSystem singleton
	CoreSystem.state_machine_manager
	CoreSystem.save_manager
	CoreSystem.audio_manager
	CoreSystem.input_manager
	CoreSystem.logger
	CoreSystem.resource_manager
	CoreSystem.scene_manager
```

## 📚 Documentation

Detailed documentation for each system:

- [State Machine System](docs/state_machine_system_en.md)
- [Serialization System](docs/serialization_system_en.md)
- [Audio System](docs/audio_system_en.md)
- [Input System](docs/input_system_en.md)
- [Logger System](docs/logger_system_en.md)
- [Resource System](docs/resource_system_en.md)
- [Scene System](docs/scene_system_en.md)

## 🌟 Examples

Check out our [example project](examples/) to see the framework in action.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💖 Support

If you find this project helpful, please consider giving it a star ⭐️
