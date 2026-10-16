class_name ModalToolBar
extends HBoxContainer
## A tool bar that is responsible for signaling about 
## adding [PolyLine2D], [LLineEdit] and other graphics.


signal modal_tool_activation_requested(tool: ModalTool) ## Emitted for [EditorContext] to execute [ModalTool].
@export var button_group: ButtonGroup ## Used for disabling the ability to press multiple buttons at once and to unpress the active button.
@export var modal_tools: Dictionary[StringName, GDScript]


func _ready() -> void:
	if button_group:
		button_group.pressed.connect(_on_button_group_button_pressed)


## Unpresses the currently pressed button of the [member button_group].
func unpress_button() -> void:
	var pressed_button: BaseButton = button_group.get_pressed_button()
	if pressed_button:
		pressed_button.button_pressed = false


func _on_button_group_button_pressed(button: BaseButton) -> void:
	if not modal_tools.has(button.name):
		return
	modal_tool_activation_requested.emit(modal_tools[button.name])
