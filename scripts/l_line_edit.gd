class_name LLineEdit
extends LineEdit


signal changed
signal deleted
signal finished_placing
const EDITABLE_PROPERTIES_NAMES: Array[StringName] = [
		&"text",
		&"alignment",
		&"grow_horizontal",
		&"grow_vertical"
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
var gizmos: Array[Gizmo]


func _ready() -> void:
	expand_to_text_length = true
	flat = true
	placeholder_text = "TEXT"
	theme_type_variation = &"LLineEdit"
	editable = false
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	changed.connect(_on_changed)


func _on_changed() -> void:
	_update_gizmo_position()


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
		_remove_gizmos()
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
	add_theme_color_override(&"font_placeholder_color", ProjectColor.selection_values[ProjectColor.Selection.TEXT])
	queue_redraw()


func remove_from_selection() -> void:
	is_selected = false
	add_theme_color_override(&"font_color", get_theme_color(&"text_color"))
	add_theme_color_override(&"font_placeholder_color", Color.from_rgba8(0, 0, 0, 128))
	remove_from_group(&"selection")
	_remove_gizmos()
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
	if is_selected:
		if gizmos.is_empty():
			_add_gizmos()
		var gizmo: Gizmo = gizmos[0]
		var gizmo_position: Vector2 = position
		gizmo_position.y += get_rect().size.y
		var gizmo_grab_size: Vector2 = Vector2(Units.mm_to_px(gizmo.radius), Units.mm_to_px(gizmo.radius)) / 1.5
		gizmo.set_begin(gizmo_position - gizmo_grab_size)
		gizmo.set_end(gizmo_position + gizmo_grab_size)
		gizmo.position_changed.connect(_on_gizmo_position_changed)
		#gizmo.grabbed.connect(_on_gizmo_grabbed.bind(point))
		#gizmo.released.connect(_on_gizmo_released)
	else:
		if not gizmos.is_empty():
			_remove_gizmos()
	queue_redraw()


func _on_gizmo_position_changed(new_position: Vector2) -> void:
	position = new_position
	position.y -= get_rect().size.y


func _add_gizmos() -> void:
	var gizmo: Gizmo = Gizmo.new()
	gizmo.graphics_node = self
	owner.add_child(gizmo)
	gizmos.append(gizmo)


func _update_gizmo_position() -> void:
	var gizmo: Gizmo = gizmos[0]
	var gizmo_position: Vector2 = position
	gizmo_position.y += get_rect().size.y
	var gizmo_grab_size: Vector2 = Vector2(Units.mm_to_px(gizmo.radius), Units.mm_to_px(gizmo.radius)) / 1.5
	gizmo.set_begin(gizmo_position - gizmo_grab_size)
	gizmo.set_end(gizmo_position + gizmo_grab_size)


func _remove_gizmos() -> void:
	for gizmo: Gizmo in gizmos:
		gizmo.queue_free()
	gizmos.clear()


func _draw() -> void:
	var is_debug: bool = get_tree().debug_collisions_hint
	if is_debug:
		var rect: Rect2 = get_rect()
		rect.position -= position
		draw_rect(rect, ProjectColor.debug_values[ProjectColor.Debug.AREA])
