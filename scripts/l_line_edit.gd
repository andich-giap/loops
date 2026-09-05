class_name LLineEdit
extends LineEdit


signal changed
signal deleted
signal finished_placing
const EDITABLE_PROPERTIES_NAMES: Array[StringName] = [
		&"text",
		&"alignment",
]
var THEME_OVERRIDABLE_PROPERTIES: Dictionary[StringName, Array] = {
	&"_theme_color_override": [
		&"text_color",
	],
	&"_theme_font_size_override": [
		&"font_size"
	],
}
@export_storage var page_data: WeakRef
var is_placing: bool = false
var is_selected: bool = false:
	set = set_is_selected


func _ready() -> void:
	expand_to_text_length = true
	flat = true
	placeholder_text = "TEXT"
	theme_type_variation = &"LLineEdit"


func _input(event: InputEvent) -> void:
	if is_placing:
		if event is InputEventMouseMotion:
			position = _get_place_position()
		if event is InputEventMouseButton:
			var mouse_button_event: InputEventMouseButton = event
			if mouse_button_event.is_released() \
				and mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
				is_placing = false
				finished_placing.emit()
				changed.emit()
	if event.is_action(&"delete"):
		deleted.emit()
		queue_free()


func _get_place_position() -> Vector2:
	var interval: Vector2 = Vector2(Units.mm_to_px(Grid.interval), Units.mm_to_px(Grid.interval))
	var place_position: Vector2
	var global_mouse_position: Vector2 = get_global_mouse_position()
	if Grid.grid_visible:
		place_position = snapped(global_mouse_position, interval)
	else:
		place_position = global_mouse_position
	return place_position


func add_to_selection() -> void:
	is_selected = true
	add_theme_color_override(&"font_color", ProjectColor.selection_values[ProjectColor.Selection.TEXT])
	queue_redraw()


func remove_from_selection() -> void:
	is_selected = false
	add_theme_color_override(&"font_color", get_theme_color(&"text_color"))
	remove_from_group(&"selection")
	queue_redraw()


func get_editable_properties() -> Array[Dictionary]:
	var editable_properties: Array[Dictionary]
	for property: Dictionary in get_property_list():
		if not EDITABLE_PROPERTIES_NAMES.has(property["name"]):
			continue
		editable_properties.append(property)
	return editable_properties


func get_theme_editable_properties() -> Dictionary[StringName, Array]:
	return THEME_OVERRIDABLE_PROPERTIES


func set_is_selected(_is_selected: bool) -> void:
	is_selected = _is_selected
	#if is_selected:
		#default_color = ProjectColor.selection_values[ProjectColor.Selection.LINE]
		#if gizmos.is_empty():
			#_add_gizmos()
		#for point: int in range(points.size()):
			#var gizmo: Gizmo = gizmos[point]
			#var gizmo_position: Vector2 = get_point_position(point)
			#var gizmo_grab_size: Vector2 = Vector2(Units.mm_to_px(gizmo.radius), Units.mm_to_px(gizmo.radius)) / 1.5
			#gizmo.set_begin(gizmo_position - gizmo_grab_size)
			#gizmo.set_end(gizmo_position + gizmo_grab_size)
			#gizmo.position_changed.connect(_on_gizmo_position_changed.bind(point))
			#gizmo.grabbed.connect(_on_gizmo_grabbed.bind(point))
			#gizmo.released.connect(_on_gizmo_released)
	#else:
		#default_color = color
		#if not gizmos.is_empty():
			#_remove_gizmos()
	queue_redraw()


func _draw() -> void:
	var is_debug: bool = get_tree().debug_collisions_hint
	if is_debug:
		var rect: Rect2 = get_rect()
		rect.position -= position
		draw_rect(rect, ProjectColor.debug_values[ProjectColor.Debug.AREA])
