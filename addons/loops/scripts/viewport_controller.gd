@tool
class_name ViewportController
extends Node2D


const SCALE_STEP: Vector2 = Vector2(1.1, 1.1)
var is_offsetting: bool = false
var can_offset: bool = true
var offset: Vector2:
	get = get_offset,
	set = set_offset
var zoom: Vector2 = Vector2.ONE:
	set = set_zoom
@onready var viewport: Viewport = get_parent()


func _input(event: InputEvent) -> void:
	if can_offset:
		process_pan(event)
	# Zoom
	if (event is InputEventMouseButton and event.is_pressed()) or event is InputEventMagnifyGesture:
		process_zoom(event)


func get_offset() -> Vector2:
	return viewport.canvas_transform.origin


func set_offset(_offset: Vector2) -> void:
	viewport.canvas_transform = viewport.canvas_transform.translated(_offset - offset)
	offset = _offset


func set_zoom(_zoom: Vector2) -> void:
	viewport.canvas_transform = viewport.canvas_transform.scaled(_zoom / zoom)
	zoom = _zoom


func process_pan(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.button_index == MouseButton.MOUSE_BUTTON_MIDDLE:
			if mouse_button_event.is_pressed():
				is_offsetting = true
			else:
				is_offsetting = false
	if event is InputEventMouseMotion:
		var mouse_motion_event: InputEventMouseMotion = event
		if is_offsetting:
				offset += mouse_motion_event.relative
	if event is InputEventScreenDrag:
		var screen_drag_event: InputEventScreenDrag = event
		offset += screen_drag_event.relative


func process_zoom(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		offset -= viewport.get_mouse_position()
		if mouse_button_event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			zoom *= Vector2.ONE / SCALE_STEP
		if mouse_button_event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
			zoom *= SCALE_STEP
		offset += viewport.get_mouse_position()
		return
	if event is InputEventMagnifyGesture:
		var magnify_gesture_event: InputEventMagnifyGesture = event
		offset -= magnify_gesture_event.position
		var factor: Vector2 = Vector2(magnify_gesture_event.factor, magnify_gesture_event.factor)
		if factor == Vector2.ZERO:
			factor = SCALE_STEP
		zoom *= factor
		print(zoom.x, factor.x)
		offset += magnify_gesture_event.position
