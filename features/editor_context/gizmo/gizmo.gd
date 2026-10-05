@tool
class_name Gizmo
extends Control


signal grabbed
signal released
signal position_changed(new_position: Vector2)
enum Type {
	CIRCLE,
	SQUARE,
	ARROW,
	PLUS,
	CROSS,
}
@export var type: Type = Type.CIRCLE:
	set = set_type
@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var radius: float = 1.0 ## Determines the radius of the [Gizmo] and its grab area.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_READ_ONLY) var radius_vector: Vector2:
	get = get_radius_vector
var is_grabbed: bool = false
var graphics_node: Node


func _init() -> void:
	mouse_default_cursor_shape = Control.CURSOR_MOVE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button_event.is_pressed():
				is_grabbed = true
				grabbed.emit()
			else:
				is_grabbed = false
				released.emit()
	if event is InputEventMouseMotion and is_grabbed:
		var place_position: Vector2 = graphics_node.call(&"_get_place_position")
		position = place_position - radius_vector / 1.5
		position_changed.emit(place_position)
		queue_redraw()


func _draw() -> void:
	match type:
		Type.CIRCLE:
			draw_type_circle()
		Type.ARROW:
			draw_type_arrow()
	var is_debug: bool = get_tree().debug_collisions_hint
	if is_debug:
		draw_rect(Rect2(Vector2(0, 0), Vector2(1, 1)), ProjectColor.debug_values[ProjectColor.Debug.AREA])


func set_type(_type: Type) -> void:
	type = _type
	queue_redraw()


func draw_type_circle() -> void:
	var circle_position: Vector2 = (get_end() - get_begin()) / 2
	
	draw_circle(circle_position, Units.mm_to_px(radius), Color.BLACK)
	draw_circle(circle_position, Units.mm_to_px(radius / 2.0), Color.WHITE)


func draw_type_arrow() -> void:
	draw_colored_polygon(
		[
			Vector2( 0, 0.0),
			Vector2( 6.0, 0.0),
			Vector2( 3.0, 6.0)
		],
		Color.AQUA
	)


func get_radius_vector() -> Vector2:
	return Vector2(Units.mm_to_px(radius), Units.mm_to_px(radius))
