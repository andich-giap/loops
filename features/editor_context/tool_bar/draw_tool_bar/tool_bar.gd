class_name DrawToolBar
extends HBoxContainer
## A tool bar that is responsible for signaling about 
## adding [PolyLine2D], [LLineEdit] and other graphics.


signal add_draw_line_requested ## Emitted for [EditorContext] to create [PolyLine2D].
signal add_text_requested ## Emitted for [EditorContext] to create [LLineEdit].
@export var button_group: ButtonGroup ## Used for disabling the ability to press multiple buttons at once and to unpress the active button.


func _ready() -> void:
	if button_group:
		button_group.pressed.connect(_on_button_group_button_pressed)


func _on_button_group_button_pressed(button: BaseButton) -> void:
	match button.name:
		"DrawLine":
			add_draw_line_requested.emit()
		"AddText":
			add_text_requested.emit()


## Unpresses the currently pressed button of the [member button_group].
func unpress_button() -> void:
	var pressed_button: BaseButton = button_group.get_pressed_button()
	if pressed_button:
		pressed_button.button_pressed = false
