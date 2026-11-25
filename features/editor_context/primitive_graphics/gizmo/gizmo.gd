@tool @icon("res://addons/at-icons/control/orbit.svg")
class_name Gizmo
extends Control
## A control for grabbing with the mouse and changing the position.


signal grabbed ## Emitted when the left mouse button is pressed under the gizmo.
signal released ## Emitted when the left mouse button is release after grabbing the gizmo.
signal position_changed(new_position: Vector2) ## Emitted when position of the gizmo is changed.
enum Type { ## Possible shapes of the gizmo.
	CIRCLE,
	SQUARE,
	ARROW,
	PLUS,
	CROSS,
}
@export var type: Type = Type.CIRCLE: ## The type of the gizmo.
	set = set_type
@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var radius: float = 1.5: ## Determines the radius of the [Gizmo] and its grab area.
	get = get_radius
var is_grabbed: bool = false: ## Determines if the gizmo is currently grabbed.
	set = set_is_grabbed
var graphics_node: Node ## The node the gizmo is being spawned from, basically a parent.
var is_selected: bool = false: ## Determines if the gizmo is currently selected.
	set = set_is_selected


func _init() -> void:
	mouse_default_cursor_shape = Control.CURSOR_MOVE


func _ready() -> void:
	add_to_group(&"upadate_on_viewport_zoom")


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
		position = place_position - _get_radius_vector()
		position_changed.emit(place_position)
		queue_redraw()


func _draw() -> void:
	var color: Color = get_theme_color(&"normal_color", &"Gizmo")
	if is_selected:
		color = get_theme_color(&"selected_color", &"Gizmo")
	if is_grabbed:
		color = get_theme_color(&"selected_color", &"Gizmo")
	match type:
		Type.CIRCLE:
			_draw_type_circle(color)
		Type.ARROW:
			_draw_type_arrow(color)
	var is_debug: bool = get_tree().debug_collisions_hint
	if is_debug:
		var rect: Rect2 = get_rect()
		rect.position -= position
		draw_rect(rect, ProjectColor.debug_values[ProjectColor.Debug.AREA])


#region setters/getters
func set_type(_type: Type) -> void:
	type = _type
	queue_redraw()


func get_radius() -> float:
	return radius / get_viewport_transform().get_scale().x


func set_is_grabbed(_is_grabbed: bool) -> void:
	is_grabbed = _is_grabbed
	queue_redraw()


func set_is_selected(_is_selected: bool) -> void:
	is_selected = _is_selected
	queue_redraw()
#endregion


func set_gizmo_position(_position: Vector2) -> void:
	#position = _position
	var gizmo_grab_size: Vector2 = _get_radius_vector()
	set_begin(_position - gizmo_grab_size)
	set_end(_position + gizmo_grab_size)


func _draw_type_circle(color: Color) -> void:
	var circle_position: Vector2 = (get_end() - get_begin()) / 2
	
	draw_circle(circle_position, Units.mm_to_px(radius), Color.BLACK)
	draw_circle(circle_position, Units.mm_to_px(radius / 2.0), color)


func _draw_type_arrow(color: Color) -> void:
	draw_colored_polygon(
		[
			Vector2( 0, 0.0),
			Vector2( 6.0, 0.0),
			Vector2( 3.0, 6.0)
		],
		color
	)


func _get_radius_vector() -> Vector2:
	return Vector2(Units.mm_to_px(radius), Units.mm_to_px(radius))


## Triggered by [signal ViewportCamera.zoom_changed]. Called on
## [method SceneTree.call_group] on [code]&"upadate_on_viewport_zoom"[/code] group.
func _on_viewport_zoom_changed() -> void:
	queue_redraw()
	set_gizmo_position(get_rect().get_center())
