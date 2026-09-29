@tool
class_name TextLineEdit
extends Control


enum VerticalAlignment {
	DOWN,
	CENTER,
	UP,
}
enum HorizontalAlignment {
	LEFT,
	CENTER,
	RIGHT,
}
@export var text: String = "":
	set = set_text
@export var font_size: int = 32:
	set = set_font_size
@export var vertical_alignment: TextLineEdit.VerticalAlignment = TextLineEdit.VerticalAlignment.DOWN:
	set = set_vertical_alignment
@export var horizontal_alignment: TextLineEdit.HorizontalAlignment = TextLineEdit.HorizontalAlignment.LEFT:
	set = set_horizontal_alignment
var _text_line: TextLine


func _ready() -> void:
	_text_line = TextLine.new()
	_text_line.add_string(text, get_theme_default_font(), font_size)
	custom_minimum_size = Vector2(_text_line.get_line_width(), font_size)
	queue_redraw()


func _draw() -> void:
	_text_line.draw(
		get_canvas_item(),
		Vector2.ZERO,
		get_theme_color(&"font_color")
	)


func set_text(_text: String) -> void:
	text = _text
	_update_text_line()
	custom_minimum_size.x = _text_line.get_line_width()


func set_font_size(_font_size: int) -> void:
	font_size = _font_size
	_update_text_line()
	custom_minimum_size = Vector2(_text_line.get_line_width(), font_size)


func set_vertical_alignment(_vertical_alignment: TextLineEdit.VerticalAlignment) -> void:
	vertical_alignment = _vertical_alignment


func set_horizontal_alignment(_horizontal_alignment: TextLineEdit.HorizontalAlignment) -> void:
	horizontal_alignment = _horizontal_alignment


func _update_text_line() -> void:
	if not _text_line:
		return
	_text_line.clear()
	_text_line.add_string(
		text,
		get_theme_default_font(),
		font_size
	)
	queue_redraw()
