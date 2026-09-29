class_name DrawToolBar
extends HBoxContainer


signal add_draw_line_requested
signal add_text_requested
@export var button_group: ButtonGroup


func _ready() -> void:
	if button_group:
		button_group.pressed.connect(_on_button_group_button_pressed)


func _on_button_group_button_pressed(button: BaseButton) -> void:
	match button.name:
		"DrawLine":
			add_draw_line_requested.emit()
		"AddText":
			add_text_requested.emit()


func unpress_button() -> void:
	var pressed_button: BaseButton = button_group.get_pressed_button()
	if pressed_button:
		pressed_button.button_pressed = false
