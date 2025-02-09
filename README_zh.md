# Godot 核心系统

<div align="center">

[English](README.md) | [简体中文](README_zh.md)

![Godot v4.4](https://img.shields.io/badge/Godot-v4.4-478cbf?logo=godot-engine&logoColor=white)
[![GitHub license](https://img.shields.io/github/license/Liweimin0512/godot_core_system)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/Liweimin0512/godot_core_system)](https://github.com/Liweimin0512/godot_core_system/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/Liweimin0512/godot_core_system)](https://github.com/Liweimin0512/godot_core_system/issues)
[![GitHub forks](https://img.shields.io/github/forks/Liweimin0512/godot_core_system)](https://github.com/Liweimin0512/godot_core_system/network)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

一个为 Godot 4.4 设计的高度模块化、易扩展的核心系统框架

[快速开始](#快速开始) •
[文档](#文档) •
[示例](#示例) •
[贡献](CONTRIBUTING.md) •
[支持](#支持)

</div>

## ✨ 特性

- 🎮 **状态机系统**：灵活强大的游戏逻辑状态管理
- 💾 **序列化系统**：易用的存档/读档功能和配置管理
- 🎵 **音频系统**：全面的音频管理，支持分类和过渡
- 🎯 **输入系统**：统一的输入处理，支持动作映射和事件管理
- 📝 **日志系统**：详细的日志系统，支持多种输出通道
- 🎨 **资源系统**：高效的资源加载和管理
- 🎬 **场景系统**：简化场景转换和管理
- 🔧 **插件架构**：易于扩展和自定义
- 📱 **项目设置集成**：通过 Godot 的项目设置配置所有系统
- 🛠️ **开发工具**：内置调试和开发工具

## 🚀 快速开始

### 前提条件

- Godot Engine 4.x
- 基本的 GDScript 和 Godot 引擎知识

### 安装

1. 从[发布页面](https://github.com/Liweimin0512/godot_core_system/releases)下载最新版本
2. 将 `godot_core_system` 文件夹复制到你的 Godot 项目的 `addons` 目录下
3. 在 Godot 编辑器中启用插件：项目 -> 项目设置 -> 插件 -> Godot Core System -> 启用

### 快速上手

```gdscript
extends Node

func _ready():
	# 通过 CoreSystem 单例访问各个管理器
	CoreSystem.state_machine_manager
	CoreSystem.save_manager
	CoreSystem.audio_manager
	CoreSystem.input_manager
	CoreSystem.logger
	CoreSystem.resource_manager
	CoreSystem.scene_manager
```

## 📚 文档

每个系统的详细文档：

- [状态机系统](docs/state_machine_system_zh.md)
- [序列化系统](docs/serialization_system_zh.md)
- [音频系统](docs/audio_system_zh.md)
- [输入系统](docs/input_system_zh.md)
- [日志系统](docs/logger_system_zh.md)
- [资源系统](docs/resource_system_zh.md)
- [场景系统](docs/scene_system_zh.md)

## 🌟 示例

查看我们的[示例项目](examples/)以了解框架的实际应用。

## 🤝 贡献

我们欢迎贡献！请查看我们的[贡献指南](CONTRIBUTING.md)了解详情。

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 💖 支持

如果你遇到任何问题或有任何建议：

1. 查看[文档](docs/)
2. 搜索[已存在的issues](https://github.com/Liweimin0512/godot_core_system/issues)
3. 创建新的[issue](https://github.com/Liweimin0512/godot_core_system/issues/new)

### 社区

- 加入我们的[Discord服务器](https://discord.gg/97ux5TnY)
- 关注我们的[itch.io](https://godot-li.itch.io/)
- 为项目点赞 ⭐ 以显示你的支持！

## 🙏 致谢

- 感谢所有为这个项目做出贡献的开发者！
- 特别感谢[老李游戏学院](https://wx.zsxq.com/group/28885154818841)的每一位同学！
- 由Godot社区用 ❤️ 构建

---

<div align="center">
由Liweimin0512用 ❤️ 构建
</div>
