class_name LLineEdit
extends LineEdit
## An interactive [LineEdit] that is used to create simple text graphics.


signal changed ## Emitted when the position is changed
signal deleted ## Emitted on deleting the [LLineEdit].
signal finished_placing ## Emitted on placing the [LLineEdit] after its creation.
const EDITABLE_PROPERTIES_NAMES: Array[StringName] = [
		&"text",
		&"alignment",
		&"vertical_alignment",
]
const THEME_OVERRIDABLE_PROPERTIES: Dictionary[StringName, Array] = {
	&"_theme_color_override": [
		&"text_color",
	],
	&"_theme_font_size_override": [
		&"font_size",
	],
}
@export var vertical_alignment: VerticalAlignment = VerticalAlignment.VERTICAL_ALIGNMENT_BOTTOM ## The alignment of the text vertically.
var is_placing: bool = false ## Determines if the text line is being placed after the creation.
var is_selected: bool = false: ## Determines if the text line is selected by the [SelectionManager].
	set = set_is_selected
var gizmos: Array[Gizmo] ## Contains [Gizmo]s of each point of the line. If the line is not selected [member gizmos] is empty.
var _page_viewport: PageViewport


func _init(edit_placement: bool = false) -> void:
	is_placing = edit_placement
	context_menu_enabled = false


func _ready() -> void:
	flat = false
	placeholder_text = "TEXT"
	theme_type_variation = &"LLineEdit"
	editable = false
	expand_to_text_length = true
	caret_blink = true
	caret_force_displayed = false
	changed.connect(_on_changed)
	text_submitted.connect(_on_text_submitted)
	focus_exited.connect(_on_focus_exited)
	add_theme_color_override(&"text_color", get_theme_color(&"font_uneditable_color", &"LLineEdit"))


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
				edit_text()
		if event.is_action(&"ui_cancel"):
			finished_placing.emit()
			queue_free()
	if event.is_action(&"delete") and not is_editing() and is_selected:
		deleted.emit()
		remove_gizmos()
		queue_free()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.double_click:
			edit_text()


func _draw() -> void:
	var is_debug: bool = get_tree().debug_collisions_hint
	if is_debug:
		var rect: Rect2 = get_rect()
		rect.position -= position
		draw_rect(rect, ProjectColor.debug_values[ProjectColor.Debug.AREA])


#region setters/getters
func set_is_selected(_is_selected: bool) -> void:
	is_selected = _is_selected
	if is_selected:
		if gizmos.is_empty():
			add_gizmos()
		var gizmo: Gizmo = gizmos[0]
		var gizmo_position: Vector2 = position
		gizmo_position.y += get_rect().size.y
		var gizmo_grab_size: Vector2 = Vector2(Units.mm_to_px(gizmo.radius), Units.mm_to_px(gizmo.radius)) / 1.5
		gizmo.set_begin(gizmo_position - gizmo_grab_size)
		gizmo.set_end(gizmo_position + gizmo_grab_size)
		if not gizmo.position_changed.is_connected(_on_gizmo_position_changed):
			gizmo.position_changed.connect(_on_gizmo_position_changed)
	else:
		if not gizmos.is_empty():
			remove_gizmos()
	queue_redraw()
#endregion


## Adds text line to the selection.
func add_to_selection() -> void:
	is_selected = true
	add_theme_color_override(&"font_uneditable_color", get_theme_color(&"text_selection_color", &"LLineEdit"))
	queue_redraw()


## Removes text line to the selection.
func remove_from_selection() -> void:
	is_selected = false
	add_theme_color_override(&"font_uneditable_color", get_theme_color(&"text_color", &"LLineEdit"))
	add_theme_color_override(&"text_color", get_theme_color(&"text_color", &"LLineEdit"))
	remove_theme_color_override(&"font_placeholder_color")
	remove_from_group(&"selection")
	remove_gizmos()
	queue_redraw()


## Focuses to the editing state.
func edit_text() -> void:
	editable = true
	caret_force_displayed = true
	edit()
	size = Vector2.ZERO


func get_editable_properties() -> Array[Dictionary]:
	var editable_properties: Array[Dictionary]
	for property: Dictionary in get_property_list():
		if not EDITABLE_PROPERTIES_NAMES.has(property["name"]):
			continue
		editable_properties.append(property)
	return editable_properties


func get_theme_editable_properties() -> Dictionary[StringName, Array]:
	return THEME_OVERRIDABLE_PROPERTIES


## Creates gizmos at the place position.
func add_gizmos() -> void:
	var gizmo: Gizmo = Gizmo.new()
	gizmo.graphics_node = self
	owner.add_child(gizmo)
	gizmos.append(gizmo)


## Removes gizmos
func remove_gizmos() -> void:
	for gizmo: Gizmo in gizmos:
		gizmo.queue_free()
	gizmos.clear()


func _on_changed() -> void:
	_update_gizmo_position()


func _on_text_submitted(_new_text: String) -> void:
	editable = false
	caret_force_displayed = false


func _on_focus_exited() -> void:
	var rect: Rect2 = get_rect()
	rect.position = Vector2.ZERO
	if rect.has_point(get_local_mouse_position()):
		return
	editable = false
	caret_force_displayed = false


func _get_place_position() -> Vector2:
	var place_position: Vector2 = _page_viewport.get_place_position()
	return place_position


func _on_gizmo_position_changed(_new_position: Vector2) -> void:
	var new_position: Vector2 = _get_place_position()
	new_position.y -= get_rect().size.y
	if position == new_position:
		return
	position = new_position
	changed.emit()


func _update_gizmo_position() -> void:
	if gizmos.is_empty():
		return
	var gizmo: Gizmo = gizmos[0]
	var gizmo_position: Vector2 = position
	gizmo_position.y += get_rect().size.y
	var gizmo_grab_size: Vector2 = Vector2(Units.mm_to_px(gizmo.radius), Units.mm_to_px(gizmo.radius)) / 1.5
	gizmo.set_begin(gizmo_position - gizmo_grab_size)
	gizmo.set_end(gizmo_position + gizmo_grab_size)
