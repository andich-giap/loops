class_name ToolBar
extends HBoxContainer


signal tool_activated(active_tool: StringName)
signal tool_deactivated()
signal graphics_added(graphics: Node)
@export var button_group: ButtonGroup
var active_tool: StringName = &""
var _active_graphics: Node:
	set = _set_active_graphics


func _ready() -> void:
	if button_group:
		button_group.pressed.connect(_on_button_group_button_pressed)
	graphics_added.connect(_set_active_graphics)


func _on_button_group_button_pressed(button: BaseButton) -> void:
	if not active_tool == &"":
		_active_graphics.queue_free()
	active_tool = button.name
	tool_activated.emit(active_tool)
	match active_tool:
		&"DrawLine":
			var poly_line_2d: PolyLine2D = PolyLine2D.new()
			poly_line_2d.is_active = true
			graphics_added.emit(poly_line_2d)
			poly_line_2d.finished_drawing.connect(
				unpress_button,
				CONNECT_ONE_SHOT
			)
		&"AddText":
			var l_line_edit: LLineEdit = LLineEdit.new()
			l_line_edit.finished_placing.connect(
				unpress_button,
				CONNECT_ONE_SHOT
			)
			graphics_added.emit(l_line_edit)


func unpress_button() -> void:
	active_tool = &""
	var pressed_button: BaseButton = button_group.get_pressed_button()
	if pressed_button:
		pressed_button.button_pressed = false
	tool_deactivated.emit()


func _input(event: InputEvent) -> void:
	if event.is_action(&"ui_cancel") and active_tool:
		_active_graphics.queue_free()
		unpress_button()


func _set_active_graphics(graphics: Node) -> void:
	_active_graphics = graphics
