extends "res://addons/godot_core_system/source/logger/console/console_interface.gd"

enum LOG_TYPE {
	LINE,
	ERROR,
	WARNING,
	DEBUG,
}

const LOG_COLORS = {
	LOG_TYPE.LINE: Color.WHITE,
	LOG_TYPE.ERROR: Color.RED,
	LOG_TYPE.WARNING: Color.YELLOW,
	LOG_TYPE.DEBUG: Color.DARK_GRAY,
}

var _console:PankuConsole = null:
	get:
		# 获取单例，如果不存在返回空
		var console = Engine.get_singleton("Panku")
		if not console:
			push_error("Panku Console not found.")
		return console
	set(_value):
		push_error("Panku Console can not be set.")

func write_line(message: String, color: Color = Color.WHITE) -> void:
	_write(message, LOG_TYPE.LINE)

func write_error(message: String) -> void:
	_write(message, LOG_TYPE.ERROR)

func write_warning(message: String) -> void:
	_write(message, LOG_TYPE.WARNING)

func write_debug(message: String) -> void:
	_write(message, LOG_TYPE.DEBUG)

func clear() -> void:
	pass

func _write(message: String, log_type: LOG_TYPE) -> void:
	if not _console:
		push_error("Panku Console not found.")
		return
	var color = LOG_COLORS[log_type]
	var formatted_message = _set_message_color(message, color)
	match log_type:
		LOG_TYPE.LINE:
			_console.notify(formatted_message)
		LOG_TYPE.ERROR:
			_console.notify("[ERROR] " + formatted_message)
		LOG_TYPE.WARNING:
			_console.notify("[WARNING] " + formatted_message)
		LOG_TYPE.DEBUG:
			_console.notify("[DEBUG] " + formatted_message)

func _set_message_color(message: String, color: Color) -> String:
	return "[color=%s]%s[/color]" % [color.to_html(), message]
