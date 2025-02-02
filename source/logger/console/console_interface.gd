extends RefCounted

## 写入一行日志
## [param message] 消息
## [param color] 颜色
func write_line(message: String, color: Color = Color.WHITE) -> void:
	push_error("ConsoleInterface.write_line() must be implemented by child class")

## 写入一行错误日志
## [param message] 消息
func write_error(message: String) -> void:
	push_error("ConsoleInterface.write_error() must be implemented by child class")

## 写入一行警告日志
## [param message] 消息
func write_warning(message: String) -> void:
	push_error("ConsoleInterface.write_warning() must be implemented by child class")

## 写入一行调试日志
## [param message] 消息
func write_debug(message: String) -> void:
	push_error("ConsoleInterface.write_debug() must be implemented by child class")

## 清空控制台
func clear() -> void:
	push_error("ConsoleInterface.clear() must be implemented by child class")
