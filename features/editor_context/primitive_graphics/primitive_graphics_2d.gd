@tool @abstract
class_name PrimitiveGraphics2D
extends Node2D


signal changed ## Emmited on changing point position.
signal deleted ## Emmited on deleting the line.
const EDITABLE_PROPERTIES_NAMES: Array[StringName] = [
		&"color",
		&"line_style",
		&"segment_length",
		&"decoration_size",
		&"closed",
		&"width",
	]
@export var line_style: LineStyle = preload("uid://x7up8gjmus1e"):
	set = set_line_style
@export var color: Color = Color.BLACK ## Color of the line.
@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var segment_length: float = 4.0: ## Distance between decorations in mm.
	set = set_segment_step
@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var decoration_size: float = 2.0: ## The size of the decoration in mm.
	set = set_decoration_size
@export_storage var bounding_box: Rect2 ## The bounding box of the line.
var is_selected: bool: ## Determines if the line is selected by the [SelectionManager].
	set = set_is_selected
@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var width: float = 10
var gizmos: Array[Gizmo] ## Contains [Gizmo]s of each point of the line. If the line is not selected [member gizmos] is empty.
var _page_viewport: PageViewport


func _ready() -> void:
	_update_bounding_box()


func set_line_style(_line_style: LineStyle) -> void:
	if line_style and line_style.changed.is_connected(changed.emit):
		line_style.changed.disconnect(changed.emit)
	if line_style and line_style.changed.is_connected(queue_redraw):
		line_style.changed.disconnect(queue_redraw)
	
	line_style = _line_style
	if line_style:
		line_style.changed.connect(changed.emit)
		line_style.changed.connect(queue_redraw)
	else:
		line_style = preload("uid://x7up8gjmus1e")
	changed.emit()
	queue_redraw()


func set_segment_step(_segment_length: float) -> void:
	segment_length = maxf(0.01, _segment_length)
	changed.emit()
	queue_redraw()


func set_decoration_size(_decoration_size: float) -> void:
	decoration_size = maxf(0.01, _decoration_size)
	changed.emit()
	queue_redraw()


func set_is_selected(_is_selected: bool) -> void:
	is_selected = _is_selected
	if is_selected:
		if gizmos.is_empty():
			add_gizmos()
	else:
		if not gizmos.is_empty():
			remove_gizmos()
	queue_redraw()


func delete() -> void:
	remove_gizmos()
	deleted.emit()
	queue_free()


## Creates gizmos at the points of the line.
@abstract func add_gizmos() -> void


## Removes gizmos.
@abstract func remove_gizmos() -> void


## Adds line to the selection.
func add_to_selection() -> void:
	is_selected = true
	add_to_group(&"selection")
	queue_redraw()


## Removes line to the selection.
func remove_from_selection() -> void:
	is_selected = false
	remove_from_group(&"selection")
	queue_redraw()


## Returns a list of possible editable properties.
func get_editable_properties() -> Array[Dictionary]:
	var editable_properties: Array[Dictionary]
	for property: Dictionary in get_property_list():
		if EDITABLE_PROPERTIES_NAMES.has(property[&"name"]):
			editable_properties.append(property)
	return editable_properties


@abstract func handle_selection_query(
	query: SelectionQuery,
	selection_receipt: SelectionReceipt,
	_selection_rect: Rect2
) -> void


## Recalculates the bounding box of a line.
@abstract func _update_bounding_box() -> void


func _get_place_position() -> Vector2:
	var place_position: Vector2 = _page_viewport.get_snapped_position().snapped_position_canvas_space
	return place_position


func _draw_debug_bounding_box() -> void:
	var is_debug: bool = get_tree().debug_collisions_hint
	if is_debug:
		draw_rect(bounding_box, ProjectColor.debug_values[ProjectColor.Debug.AREA])
