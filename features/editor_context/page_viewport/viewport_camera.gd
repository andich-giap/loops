class_name VewportCamera
extends Node2D
## CAD-like camera that manipulates the [member Viewport.canvas_transform] of [member viewport].


const SCALE_STEP: Vector2 = Vector2(1.1, 1.1)
@export var viewport: Viewport


func _input(event: InputEvent) -> void:
	# pan
	if event is InputEventMouseMotion:
		var mouse_motion_event: InputEventMouseMotion = event
		if mouse_motion_event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			viewport.canvas_transform = viewport.canvas_transform.translated(mouse_motion_event.relative)
	# zoom
	if event is InputEventMouseButton and event.is_pressed():
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.button_index != MOUSE_BUTTON_WHEEL_DOWN and mouse_button_event.button_index != MOUSE_BUTTON_WHEEL_UP:
			return
		viewport.canvas_transform = viewport.canvas_transform.translated(-viewport.get_mouse_position())
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			viewport.canvas_transform = viewport.canvas_transform.scaled(Vector2.ONE / SCALE_STEP)
		elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			viewport.canvas_transform = viewport.canvas_transform.scaled(SCALE_STEP)
		viewport.canvas_transform = viewport.canvas_transform.translated(viewport.get_mouse_position())
