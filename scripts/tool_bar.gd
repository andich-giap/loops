class_name ToolBar
extends HBoxContainer


signal tool_activated(active_tool: StringName)
signal tool_deactivated()
signal graphics_added(graphics: Node2D)
@export var button_group: ButtonGroup
@export var default_poly_line_2d_width: float = 1.0
var active_tool: StringName = &""


func _ready() -> void:
	if button_group:
		button_group.pressed.connect(_on_button_group_button_pressed)


func _on_button_group_button_pressed(button: BaseButton) -> void:
	if not active_tool == &"":
		return
	active_tool = button.name
	tool_activated.emit(active_tool)
	match active_tool:
		&"DrawLine":
			var poly_line_2d: PolyLine2D = PolyLine2D.new()
			poly_line_2d.is_active = true
			poly_line_2d.width = default_poly_line_2d_width
			graphics_added.emit(poly_line_2d)
			poly_line_2d.finished_drawing.connect(
				unpress_button,
				CONNECT_ONE_SHOT
			)


func unpress_button() -> void:
	active_tool = &""
	var pressed_button: BaseButton = button_group.get_pressed_button()
	if pressed_button:
		pressed_button.button_pressed = false
	tool_deactivated.emit()


func _input(event: InputEvent) -> void:
	if event.is_action(&"ui_cancel"):
		unpress_button()
