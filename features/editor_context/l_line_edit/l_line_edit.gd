class_name LLineEdit
extends LineEdit
## An interactive [LineEdit] that is used to create simple text graphics.


signal changed ## Emitted when the position is changed
signal deleted ## Emitted on deleting the [LLineEdit].
signal text_editing_toggled(toggled_on: bool) ## Emitted when triggering [method edit].
signal position_editing_toggled(toggled_on: bool) ## Emitted when grabbing or releazing a [Gizmo].
const EDITABLE_PROPERTIES_NAMES: Array[StringName] = [
		&"text",
		&"horizontal_alignment",
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
@export var horizontal_alignment: HorizontalAlignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT: ## The alignment of the text horizontally.
	set = set_text_horizontal_alignment
@export var vertical_alignment: VerticalAlignment = VerticalAlignment.VERTICAL_ALIGNMENT_BOTTOM: ## The alignment of the text vertically.
	set = set_text_vertical_alignment
var is_selected: bool = false: ## Determines if the text line is selected by the [SelectionManager].
	set = set_is_selected
var gizmos: Array[Gizmo] ## Contains [Gizmo]s of each point of the line. If the line is not selected [member gizmos] is empty.
var _page_viewport: PageViewport


func _ready() -> void:
	context_menu_enabled = false
	flat = false
	placeholder_text = "TEXT"
	theme_type_variation = &"LLineEdit"
	editable = false
	expand_to_text_length = true
	caret_blink = true
	caret_force_displayed = false
	selecting_enabled = false
	changed.connect(_on_changed)
	text_submitted.connect(finish_editing.unbind(1))
	add_theme_color_override(&"text_color", get_theme_color(&"clear_button_color", &"LLineEdit"))
	add_theme_color_override(&"font_uneditable_color", get_theme_color(&"clear_button_color", &"LLineEdit"))


func _draw() -> void:
	var is_debug: bool = get_tree().debug_collisions_hint
	if is_debug:
		var rect: Rect2 = get_rect()
		rect.position -= position
		draw_rect(rect, ProjectColor.debug_values[ProjectColor.Debug.AREA])


func _validate_property(property: Dictionary) -> void:
	if property["name"] == &"horizontal_alignment":
		var hint_string: String = property["hint_string"]
		property["hint_string"] = hint_string.split(",Horizontal Alignment Fill")[0]
	elif property["name"] == &"vertical_alignment":
		var hint_string: String = property["hint_string"]
		property["hint_string"] = hint_string.split(",Vertical Alignment Fill")[0]


#region setters/getters
func set_is_selected(_is_selected: bool) -> void:
	is_selected = _is_selected
	queue_redraw()


func set_text_horizontal_alignment(_horizontal_alignment: HorizontalAlignment) -> void:
	if horizontal_alignment == _horizontal_alignment:
		return
	horizontal_alignment = _horizontal_alignment
	match horizontal_alignment:
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT:
			if vertical_alignment == VerticalAlignment.VERTICAL_ALIGNMENT_BOTTOM:
				offset_transform_position_ratio.x = 0.0
				offset_transform_enabled = false
				return
			offset_transform_enabled = false
			offset_transform_position_ratio.x = 0.0
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER:
			offset_transform_enabled = true
			offset_transform_position_ratio.x = -0.5
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT:
			offset_transform_enabled = true
			offset_transform_position_ratio.x = -1.0
		HorizontalAlignment.HORIZONTAL_ALIGNMENT_FILL:
			offset_transform_enabled = false
			offset_transform_position_ratio.x = 0.0


func set_text_vertical_alignment(_vertical_alignment: VerticalAlignment) -> void:
	if vertical_alignment == _vertical_alignment:
		return
	vertical_alignment = _vertical_alignment
	match vertical_alignment:
		VerticalAlignment.VERTICAL_ALIGNMENT_BOTTOM:
			if vertical_alignment == HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT:
				offset_transform_position_ratio.y = 0.0
				offset_transform_enabled = false
				return
			offset_transform_enabled = false
			offset_transform_position_ratio.y = 0.0
		VerticalAlignment.VERTICAL_ALIGNMENT_CENTER:
			offset_transform_enabled = true
			offset_transform_position_ratio.y = 0.5
		VerticalAlignment.VERTICAL_ALIGNMENT_TOP:
			offset_transform_enabled = true
			offset_transform_position_ratio.y = 1.0
		VerticalAlignment.VERTICAL_ALIGNMENT_FILL:
			offset_transform_enabled = false
			offset_transform_position_ratio.y = 0.0
#endregion


## Adds text line to the selection.
func add_to_selection() -> void:
	is_selected = true
	if gizmos.is_empty():
		add_gizmos()
	add_to_group(&"selection")
	add_theme_color_override(&"font_uneditable_color", get_theme_color(&"text_selection_color", &"LLineEdit"))
	queue_redraw()


## Removes text line to the selection.
func remove_from_selection() -> void:
	is_selected = false
	add_theme_color_override(&"font_uneditable_color", get_theme_color(&"text_color", &"LLineEdit"))
	add_theme_color_override(&"text_color", get_theme_color(&"text_color", &"LLineEdit"))
	add_theme_color_override(&"clear_button_color", get_theme_color(&"text_color", &"LLineEdit"))
	remove_theme_color_override(&"font_placeholder_color")
	remove_from_group(&"selection")
	remove_gizmos()
	queue_redraw()


## Focuses to the editing state.
func edit_text() -> void:
	text_editing_toggled.emit(true)
	selecting_enabled = true
	editable = true
	caret_force_displayed = true
	edit()
	size = Vector2.ZERO


## Executes when User exited the focus of the line edit or submits the text.
func finish_editing() -> void:
	text_editing_toggled.emit(false)
	var rect: Rect2 = get_rect()
	rect.position = Vector2.ZERO
	if rect.has_point(get_local_mouse_position()):
		return
	editable = false
	caret_force_displayed = false
	selecting_enabled = false


## Returns a list of possible editable properties.
func get_editable_properties() -> Array[Dictionary]:
	var editable_properties: Array[Dictionary]
	for property: Dictionary in get_property_list():
		if not EDITABLE_PROPERTIES_NAMES.has(property["name"]):
			continue
		editable_properties.append(property)
	return editable_properties


## Returns a dictionary of possible editable theme properties, the keys
## are the callable names that are stripped of the beginning (i.e. 
## the key for [code]add_theme_color_override[/code] is [code]_theme_color_override[/code])
func get_theme_overridable_properties() -> Dictionary[StringName, Array]:
	return THEME_OVERRIDABLE_PROPERTIES


## Creates gizmos at the place position.
func add_gizmos() -> void:
	var gizmo: Gizmo = Gizmo.new()
	gizmo.graphics_node = self
	get_parent().add_child(gizmo)
	gizmo.set_gizmo_position(position + Vector2(0.0, get_line_height()))
	if not gizmo.position_changed.is_connected(_on_gizmo_position_changed):
		gizmo.position_changed.connect(_on_gizmo_position_changed)
	gizmos.append(gizmo)
	gizmo.grabbed.connect(position_editing_toggled.emit.bind(true))
	gizmo.released.connect(position_editing_toggled.emit.bind(false))


## Removes gizmos
func remove_gizmos() -> void:
	for gizmo: Gizmo in gizmos:
		gizmo.grabbed.disconnect(position_editing_toggled.emit)
		gizmo.released.disconnect(position_editing_toggled.emit)
		gizmo.position_changed.disconnect(_on_gizmo_position_changed)
		gizmo.queue_free()
	gizmos.clear()


## Returns the length of the control. The length always shrinks to the
## character length upon editing text.
func get_line_width() -> float:
	return get_rect().size.x


## Returns the height of the control
func get_line_height() -> float:
	return get_rect().size.y


## Delete the [LLineEdit].
func delete() -> void:
	remove_gizmos()
	deleted.emit()
	queue_free()


func _on_changed() -> void:
	_update_gizmo_position()
	size = Vector2.ZERO


func _get_place_position() -> Vector2:
	var place_position: Vector2 = _page_viewport.get_snapped_position().snapped_position_canvas_space
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
	gizmo.set_gizmo_position(position + Vector2(0.0, get_line_height()))


func set_font_size(font_size: int) -> void:
	add_theme_font_size_override(&"font_size", font_size)
