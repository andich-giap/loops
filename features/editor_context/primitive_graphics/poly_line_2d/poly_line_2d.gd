@tool
@icon("res://resources/icons/line_2d.res")
class_name PolyLine2D
extends PrimitiveGraphics2D
## An interactive [Line2D] that is used to create simple graphics.


signal points_editing_toggled(toggled_on: bool) ## Emitted when grabbing or releazing a [Gizmo].
const DISTANCE_TO_CURSOR: float = 5.0 ## Minimum distance required for drawing circle at [member _new_point_position].
const DEBUG_CURSOR_SIZE: float = 5.0
@export_storage var points: PackedVector2Array = PackedVector2Array()
@export var closed: bool = false:
	set = set_closed
var _can_create_new_point: bool = false
var _new_point_position: Vector2
var _previous_point_position: Vector2


func _init() -> void:
	if width == 10.0:
		width = Units.mm_to_px(0.5)


func _draw() -> void:
	_draw_debug_bounding_box()
	
	var context: DrawLineContext = DrawLineContext.new()
	context.canvas_item = self
	if is_selected:
		context.color = ProjectColor.selection_values[ProjectColor.Selection.LINE]
	else:
		context.color = color
	context.size_multiplier = decoration_size
	context.width = width
	
	var point_count: int = points.size() - 1
	if closed:
		point_count += 1
	
	for point: int in range(point_count):
		var current_position: Vector2 = get_point_position(point)
		var next_index: int = wrapi(point + 1, 0, points.size())
		var next_position: Vector2 = get_point_position(next_index)
		line_style.line_style_definition.draw_segment(context, current_position, next_position)
		
		if closed or not point == 0:
			var prev_index: int = wrapi(point - 1, 0, points.size())
			line_style.line_style_definition.draw_joint(
				context,
				current_position,
				current_position.direction_to(points[prev_index]),
				current_position.direction_to(next_position)
			)
		
		var delta: Vector2 = next_position - current_position
		var line_length: float = delta.length()
		
		var step_px: float
		var step_mm: float = line_style.line_style_definition.get_step()
		if step_mm > 0.0:
			step_px = Units.mm_to_px(step_mm)
		else:
			step_px = Units.mm_to_px(segment_length)
		step_px *= decoration_size
		var direction: Vector2 = current_position.direction_to(next_position)
		var step: Vector2 = direction * step_px
		
		var segment_count: int = int(line_length / step_px)
		var starting_decoration_position: Vector2 = current_position - step / 4
		
		for line_decoration: LineDecoration in line_style.line_decorations:
			var decoration_position: Vector2 = starting_decoration_position
			for segment: int in segment_count:
				decoration_position += step
				var offset_px: float = Units.mm_to_px(line_decoration.position_offset)
				var final_position: Vector2 = decoration_position + direction * offset_px
				line_decoration.draw_decoration(
					context,
					final_position,
					delta.normalized(),
					delta.normalized().rotated(PI/2.0),
					segment
				)
		
	if points.size() > 1 and not closed:
		line_style.line_style_definition.draw_cap(context, points[0], points[1].direction_to(points[0]), true)
		line_style.line_style_definition.draw_cap(context, points[-1], points[-2].direction_to(points[-1]), false)


#region getters/setters
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


func set_closed(_closed: bool) -> void:
	closed = _closed
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


## Creates gizmos at the points of the line.
func add_gizmos() -> void:
	for _point: int in range(points.size()):
		var gizmo: Gizmo = Gizmo.new()
		gizmo.graphics_node = self
		owner.add_child(gizmo)
		gizmo.set_gizmo_position(get_point_position(_point) + position)
		gizmo.position_changed.connect(_on_gizmo_position_changed.bind(_point))
		gizmo.grabbed.connect(_on_gizmo_grabbed.bind(_point))
		gizmo.released.connect(_on_gizmo_released)
		gizmos.append(gizmo)


## Removes gizmos.
func remove_gizmos() -> void:
	for gizmo: Gizmo in gizmos:
		gizmo.position_changed.disconnect(_on_gizmo_position_changed)
		gizmo.grabbed.disconnect(_on_gizmo_grabbed)
		gizmo.released.disconnect(_on_gizmo_released)
		gizmo.queue_free()
	gizmos.clear()


## Selects individual points
func select_points(_points: PackedInt32Array = []) -> void:
	remove_gizmos()
	add_gizmos()
	for gizmo: int in _points:
		gizmos[gizmo].is_selected = true


## Deselects individual points.
func deselect_points(_points: PackedInt32Array = []) -> void:
	if _points.is_empty():
		_points = PackedInt32Array(range(gizmos.size()))
	for gizmo: int in _points:
		gizmos[gizmo].is_selected = false


func delete() -> void:
	remove_gizmos()
	deleted.emit()
	queue_free()


func handle_selection_query(
	query: SelectionQuery,
	receipt: SelectionReceipt,
	selection_rect: Rect2
) -> void:
	var poly_line_points: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		poly_line_points.append(point + position)
	if query.type == SelectionQuery.Type.POINT:
		for point: int in range(poly_line_points.size()):
			var point_inside_selection: bool = Geometry2D.is_point_in_polygon(
				poly_line_points[point],
				SelectionManager.rect2_to_packed_vector2_array(selection_rect)
			)
			if not receipt.selected_points.has(self):
				receipt.selected_points[self] = PackedInt32Array()
			if point_inside_selection:
				receipt.selected_points[self].append(point)
	else:
		var intersection: Array[PackedVector2Array] = Geometry2D.intersect_polyline_with_polygon(
			poly_line_points,
			SelectionManager.rect2_to_packed_vector2_array(selection_rect)
			)
		if not intersection.is_empty():
			receipt.selected_nodes.append(self)



## Recalculates the bounding box of a line.
func _update_bounding_box() -> void:
	if points.size() < 2:
		bounding_box = Rect2()
		return
	bounding_box = Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		bounding_box = bounding_box.expand(point)


func _on_gizmo_position_changed(new_position: Vector2, point: int) -> void:
	set_point_position(point, new_position - position)


func _on_gizmo_grabbed(point: int) -> void:
	_previous_point_position = get_point_position(point)
	points_editing_toggled.emit(true)


func _on_gizmo_released() -> void:
	bounding_box = Rect2(points[0], Vector2(1, 1))
	for point_position: Vector2 in points:
		bounding_box = bounding_box.expand(point_position)
	changed.emit()
	queue_redraw()
	points_editing_toggled.emit(false)


func _get_place_position() -> Vector2:
	var place_position: Vector2 = _page_viewport.get_snapped_position().snapped_position_canvas_space
	if Grid.is_orthogonal and not get_point_count() <= 1:
		if abs((place_position - _previous_point_position).normalized().dot(Vector2.RIGHT)) <= 0.5:
			place_position = Vector2(_previous_point_position.x, place_position.y)
		else:
			place_position = Vector2(place_position.x, _previous_point_position.y)
	return place_position


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


func get_point_position(index: int) -> Vector2:
	if points.size() == 0:
		push_error("Invalid index when calling get_point_position relative to " + to_string() + ". Point count is " + str(get_point_count()))
		return Vector2.ZERO
	return points[index]


func set_point_position(index: int, point_position: Vector2) -> void:
	points[index] = point_position
	_update_bounding_box()
	queue_redraw()


func get_point_count() -> int:
	return points.size()


func add_point(point_position: Vector2, index: int = -1) -> void:
	if index < 0:
		points.append(point_position)
	else:
		points.insert(index, point_position)
	_update_bounding_box()
	queue_redraw()


func remove_point(index: int) -> void:
	points.remove_at(index)
	_update_bounding_box()
	queue_redraw()


func clear_points() -> void:
	_update_bounding_box()
	points.clear()
	queue_redraw()
