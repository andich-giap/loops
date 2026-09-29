class_name ToolBar
extends HBoxContainer


signal add_draw_line_requested
signal add_text_requested
signal ortho_requested(toggled_on: bool)
signal grid_requested(toggled_on: bool)
@onready var draw_tool_bar: DrawToolBar = %DrawToolBar
@onready var modes_bar: ModesBar = %ModesBar


func _ready() -> void:
	draw_tool_bar.add_draw_line_requested.connect(add_draw_line_requested.emit)
	draw_tool_bar.add_text_requested.connect(add_text_requested.emit)
	
	modes_bar.ortho_requested.connect(ortho_requested.emit)
	modes_bar.grid_requested.connect(grid_requested.emit)
