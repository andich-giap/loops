@tool
class_name PolyLine2D
extends Line2D
## An interactive [Line2D] that is used to create simple graphics.


signal changed ## Emmited on changing the line [member decoration], [member segment_step], [member decoration_size] or point position is changed.
signal deleted ## Emmited on deleting the line.
signal finished_drawing ## Emitted on confirming the drawing of the line after creating.
enum DecorationType { ## Tye type line decorations.
	NONE, ## No decorations.
	LINE, ## A short line decoration at 45 degrees angele.
	CIRCLE, ## A circle decoration.
}
const DISTANCE_TO_CURSOR: float = 5.0 ## Minimum distance required for drawing circle at [member _new_point_position].
const DEBUG_CURSOR_SIZE: float = 5.0
const EDITABLE_PROPERTIES_NAMES: Array[StringName] = [
		&"color",
		&"segment_length",
		&"decoration",
		&"decoration_size",
		&"closed",
		&"width",
	]
static var default_width: float = Units.mm_to_px(1.0) ## The default width of the line.
@export var color: Color = Color.BLACK ## Color of the line.
@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var segment_length: float = Units.mm_to_px(3.0): ## Distance between decorations.
	set = set_segment_step
@export var decoration: DecorationType: ## The type of decoration.
	set = set_decoration
@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var decoration_size: float = Units.mm_to_px(5.0): ## The size of the decoration.
	set = set_decoration_size
@export_storage var bounding_box: Rect2 ## The bounding box of the line.
var is_selected: bool: ## Determines if the line is selected by the [SelectionManager].
	set = set_is_selected
var is_active: bool = false ## Determines if the line is currently edited after being placed.
var selected_points: Array[int] ## Indeces of selected points.
var gizmos: Array[Gizmo] ## Contains [Gizmo]s of each point of the line. If the line is not selected [member gizmos] is empty.
var _can_create_new_point: bool = false ## Determines if the new point can be created.
var _new_point_position: Vector2 ## The position of the new point.
var _active_point: int ## Currently active point to be placed.
var _previous_point_position: Vector2
var _page_viewport: PageViewport


func _init(edit: bool = false) -> void:
	width = default_width
	default_color = color
	is_active = edit


func _input(event: InputEvent) -> void:
	if is_active and event is InputEventMouseMotion:
		# Draw new point position on mouse hover
		_check_for_closest_point_to_cursor()
		if _active_point >= 0 and points.size() > 0:
			var place_position: Vector2 = _get_place_position()
			set_point_position(_active_point, place_position)
		queue_redraw()
	
	if is_active and event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.is_released():
			var place_position: Vector2 = _get_place_position()
			_previous_point_position = place_position
			if points.size() == 0:
				add_point(place_position)
			add_point(place_position)
			var last_index: int = get_point_count() - 1
			set_point_position(last_index, place_position)
			last_index = get_point_count() - 1
			_active_point = last_index
			queue_redraw()
			
			# Set bounding_box
			update_bounding_box()
		
		if mouse_button_event.button_index == MOUSE_BUTTON_RIGHT \
			and mouse_button_event.is_released():
			stop_drawing()
		if ((event.is_action(&"zoom_in")
			or event.is_action(&"zoom_out"))
			and not _active_point == -1):
			var place_position: Vector2 = _get_place_position()
			set_point_position(_active_point, place_position)
	
	if is_active and event.is_action(&"ui_cancel"):
		stop_drawing()
	
	if is_selected and event.is_action(&"delete"):
		remove_gizmos()
		deleted.emit()
		queue_free()


func _draw() -> void:
	var is_debug: bool = get_tree().debug_collisions_hint
	if _can_create_new_point and is_selected and is_debug:
		draw_circle(get_local_mouse_position(), DISTANCE_TO_CURSOR, Color(0.0, 0.651, 0.208, 0.482))
		draw_circle(_new_point_position, DEBUG_CURSOR_SIZE/2.0, default_color)
	for point: int in points.size():
		if point == points.size() - 1:
			continue
		var current_position: Vector2 = get_point_position(point)
		var next_position: Vector2 = get_point_position(point + 1)
		var line_length: float = (current_position - next_position).length()
		var segment_count: int = int(line_length / Units.mm_to_px(segment_length))
		for step: int in segment_count:
			var draw_position: Vector2 = (
				current_position +
				(next_position - current_position).normalized() *
				Units.mm_to_px(segment_length) *
				step
			)
			var distance_to_end: float = (draw_position - next_position).length()
			if distance_to_end < Units.mm_to_px(segment_length): continue
			_draw_decoration(draw_position, distance_to_end, false, current_position, next_position)
		if point == points.size() - 2:
			_draw_decoration(next_position, false, true, next_position, next_position)
	
	if is_debug:
		draw_rect(bounding_box, ProjectColor.debug_values[ProjectColor.Debug.AREA])


func _validate_property(property: Dictionary) -> void:
	if property["name"] == &"width":
		property["hint_string"] = "suffix: mm"


#region getters/setters
func set_segment_step(_segment_length: float) -> void:
	segment_length = maxf(0.01, _segment_length)
	changed.emit()
	queue_redraw()


func set_decoration(_decoration: DecorationType) -> void:
	if _decoration == DecorationType.LINE:
		color = Color.WHITE
	elif _decoration == DecorationType.CIRCLE:
		color = Color(Color.WHITE, 0.0)
	decoration = _decoration
	changed.emit()
	queue_redraw()


func set_decoration_size(_decoration_size: float) -> void:
	decoration_size = _decoration_size
	changed.emit()
	queue_redraw()


func set_is_selected(_is_selected: bool) -> void:
	is_selected = _is_selected
	if is_selected:
		default_color = ProjectColor.selection_values[ProjectColor.Selection.LINE]
		if gizmos.is_empty():
			add_gizmos()
		for point: int in range(points.size()):
			var gizmo: Gizmo = gizmos[point]
			gizmo.set_gizmo_position(get_point_position(point))
			gizmo.position_changed.connect(_on_gizmo_position_changed.bind(point))
			gizmo.grabbed.connect(_on_gizmo_grabbed.bind(point))
			gizmo.released.connect(_on_gizmo_released)
	else:
		default_color = color
		if not gizmos.is_empty():
			remove_gizmos()
	queue_redraw()
#endregion


## Gets the closest position to a specified [param point_position].
func get_closest_position_to_point(point_position: Vector2) -> Vector2:
	var closest_point: Vector2
	var minimum_distance: float
	for point: int in points.size():
		if point == points.size() - 1: continue
		var closest_point_on_segment: Vector2 = Geometry2D.get_closest_point_to_segment(
			point_position,
			points[point],
			points[point + 1]
		)
		var distance: float = point_position.distance_to(closest_point_on_segment)
		if point == 0:
			minimum_distance = distance
			closest_point = closest_point_on_segment
			continue
		if distance < minimum_distance:
			minimum_distance = distance
			closest_point = closest_point_on_segment
			continue
	return closest_point


## Stops the drawing of the [PolyLine2D].
func stop_drawing() -> void:
	remove_point(_active_point)
	is_active = false
	_active_point = -1
	finished_drawing.emit()
	queue_redraw()


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


## Creates gizmos at the points of the line.
func add_gizmos() -> void:
	for _point: int in range(points.size()):
		var gizmo: Gizmo = Gizmo.new()
		gizmo.graphics_node = self
		owner.add_child(gizmo)
		gizmos.append(gizmo)


## Removes gizmos.
func remove_gizmos() -> void:
	for gizmo: Gizmo in gizmos:
		gizmo.queue_free()
	gizmos.clear()


## Returns a list of possible editable properties.
func get_editable_properties() -> Array[Dictionary]:
	var editable_properties: Array[Dictionary]
	for property: Dictionary in get_property_list():
		if not EDITABLE_PROPERTIES_NAMES.has(property["name"]):
			continue
		editable_properties.append(property)
	return editable_properties


## Recalculates the bounding box of a line.
func update_bounding_box() -> void:
	if bounding_box.has_area():
		bounding_box = bounding_box.expand(points[_active_point])
	elif points.size() >= 2:
		bounding_box.position = points[0]
		for point: Vector2 in points:
			bounding_box = bounding_box.expand(point)


func _on_gizmo_position_changed(new_position: Vector2, point: int) -> void:
	set_point_position(point, new_position)


func _on_gizmo_grabbed(point: int) -> void:
	_previous_point_position = get_point_position(point)


func _on_gizmo_released() -> void:
	bounding_box = Rect2(points[0], Vector2(1, 1))
	for point_position: Vector2 in points:
		bounding_box = bounding_box.expand(point_position)
	changed.emit()
	queue_redraw()


func _get_place_position() -> Vector2:
	var place_position: Vector2 = _page_viewport.get_place_position()
	if Grid.is_orthogonal and not get_point_count() <= 1:
		if abs((place_position - _previous_point_position).normalized().dot(Vector2.RIGHT)) <= 0.5:
			place_position = Vector2(_previous_point_position.x, place_position.y)
		else:
			place_position = Vector2(place_position.x, _previous_point_position.y)
	return place_position


func _draw_decoration(decoration_position: Vector2, distance_to_end: float = 0.0, is_end_point: bool = false, current_position: Vector2 = Vector2.ZERO, next_position: Vector2 = Vector2.ZERO) -> void:
	match decoration:
		DecorationType.NONE:
			return
		DecorationType.LINE:
			var angle: float = current_position.angle_to_point(next_position)
			var factor: float = remap(angle, 0.0, PI/4, 0.0, 1.0)
			var start: Vector2 = (Vector2(-1, 1) / sqrt(2.0) * Units.mm_to_px(decoration_size)) / 2.0
			var end: Vector2 = (Vector2(1, -1) / sqrt(2.0) * Units.mm_to_px(decoration_size)) / 2.0
			start = start.rotated(PI/4 * factor)
			end = end.rotated(PI/4 * factor)
			draw_line(
				decoration_position + start,
				decoration_position + end,
				default_color,
				Units.mm_to_px(width) / 2.0
			)
		DecorationType.CIRCLE:
			if is_end_point:
				draw_circle(
					decoration_position,
					Units.mm_to_px(decoration_size),
					default_color,
					false,
					Units.mm_to_px(width)
				)
				return
			var end_vector: Vector2 = (next_position - current_position).normalized()
			var end_position: Vector2 = decoration_position + end_vector * (Units.mm_to_px(segment_length) - Units.mm_to_px(decoration_size))
			if distance_to_end < Units.mm_to_px(segment_length) * 2.0:
				end_position = decoration_position + end_vector * ((decoration_position - next_position).length() - Units.mm_to_px(decoration_size))
			draw_line(
				decoration_position + end_vector * Units.mm_to_px(decoration_size),
				end_position,
				default_color,
				Units.mm_to_px(width),
			)
			draw_circle(
				decoration_position,
				Units.mm_to_px(decoration_size),
				default_color,
				false,
				Units.mm_to_px(width)
			)


func _check_for_closest_point_to_cursor() -> void:
	if points.size() < 1: return
	var mouse_position: Vector2 = get_local_mouse_position()
	var result: Array[Vector2]
	for point: int in points.size():
		if point == points.size() - 1: continue
		var segment_position: Vector2 = Geometry2D.get_closest_point_to_segment(
			mouse_position,
			points[point],
			points[point + 1]
		)
		if mouse_position.distance_to(segment_position) > DISTANCE_TO_CURSOR: continue
		result.append(segment_position)
	result.sort_custom(_sort_distances)
	if result.size() == 0:
		if _can_create_new_point:
			_can_create_new_point = false
			queue_redraw()
		return
	_new_point_position = result[0]
	_can_create_new_point = true


func _sort_distances(pos_a: Vector2, pos_b: Vector2) -> bool:
	var mouse_position: Vector2 = get_local_mouse_position()
	return mouse_position.distance_to(pos_a) < mouse_position.distance_to(pos_b)
