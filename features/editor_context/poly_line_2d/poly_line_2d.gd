@tool
class_name PolyLine2D
extends Line2D
## An interactive [Line2D] that is used to create simple graphics.
# TODO Currently when decoration is set to SEGMENTED there is no
# implementation for the joint_mode BEVEL.


signal changed ## Emmited on changing the line [member decoration], [member segment_step], [member decoration_size] or point position is changed.
signal deleted ## Emmited on deleting the line.
signal points_editing_toggled(toggled_on: bool) ## Emitted when grabbing or releazing a [Gizmo].
enum LineType {
	BY_LAYER,
	SOLID,
	DASHED,
	DASH_DOT,
	DOUBLE,
}
enum DecorationType { ## Type of line decorations.
	NONE, ## No decorations.
	SEGMENTED,
	DASH_DECORATION, ## A short line decoration at 45 degrees angele.
	CIRCLE, ## A circle decoration.
}
const INV_SQRT2: float = 1 / sqrt(2)  # 1 / sqrt(2)
const TICK_BASE: Vector2 = Vector2(-INV_SQRT2, INV_SQRT2)  # unit diagonal
const DISTANCE_TO_CURSOR: float = 5.0 ## Minimum distance required for drawing circle at [member _new_point_position].
const DEBUG_CURSOR_SIZE: float = 5.0
const EDITABLE_PROPERTIES_NAMES: Array[StringName] = [
		&"color",
		&"segment_length",
		&"decoration",
		&"decoration_size",
		&"closed",
		&"width",
		&"joint_mode",
		&"begin_cap_mode",
		&"end_cap_mode",
	]
@export_tool_button("Add Line Decoration") var tool_add_line_decoration: Callable = _tool_add_line_decoration
@export_tool_button("Remove Line Decoration") var tool_remove_line_decoration: Callable = _tool_remove_line_decoration
@export var line_style: LineStyle = preload("uid://djogojtvrl0i5"):
	set = set_line_style
@export var line_decorations: Array[LineDecoration]:
	set = set_line_decorations
@export var color: Color = Color.BLACK ## Color of the line.
@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var segment_length: float = 4.0: ## Distance between decorations in mm.
	set = set_segment_step
@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var decoration_size: float = 2.0: ## The size of the decoration in mm.
	set = set_decoration_size
@export_storage var bounding_box: Rect2 ## The bounding box of the line.
var is_selected: bool: ## Determines if the line is selected by the [SelectionManager].
	set = set_is_selected
var gizmos: Array[Gizmo] ## Contains [Gizmo]s of each point of the line. If the line is not selected [member gizmos] is empty.
var _can_create_new_point: bool = false
var _new_point_position: Vector2
var _previous_point_position: Vector2
var _page_viewport: PageViewport


func _init() -> void:
	if width == 10.0:
		width = Units.mm_to_px(0.5)


func _ready() -> void:
	if line_style._uses_builtin_line:
		default_color = color
	else:
		default_color = Color.TRANSPARENT
	line_decorations = [preload("uid://47i8nm1hawg1")]
	_update_bounding_box()


func _draw() -> void:
	var is_debug: bool = get_tree().debug_collisions_hint
	if is_debug:
		draw_rect(bounding_box, ProjectColor.debug_values[ProjectColor.Debug.AREA])
	
	var context: DrawLineContext = DrawLineContext.new()
	context.canvas_item = self
	if is_selected:
		context.color = ProjectColor.selection_values[ProjectColor.Selection.LINE]
	else:
		context.color = color
	context.size_multiplier = decoration_size
	context.width = width
	
	for point: int in range(points.size() - 1):
		var current_position: Vector2 = get_point_position(point)
		var next_position: Vector2 = get_point_position(point + 1)
		
		
		line_style.draw_segment(context, current_position, next_position)
		
		if not point == 0:
			line_style.draw_joint(
				context,
				current_position,
				current_position.direction_to(points[point-1]),
				current_position.direction_to(next_position)
			)
		
		
		var delta: Vector2 = next_position - current_position
		var line_length: float = delta.length()
		
		var step_mm: float = line_style.get_step()
		if step_mm <= 0.0:
			step_mm = Units.mm_to_px(segment_length)
		
		var step_px: float = Units.mm_to_px(step_mm)
		var direction: Vector2 = current_position.direction_to(next_position)
		var step: Vector2 = direction * step_px
		
		var segment_count: int = int(line_length / step_px) - 1
		var decoration_position: Vector2 = current_position + step / 2.0
		
		for line_decoration: LineDecoration in line_decorations:
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
		
	if points.size() > 1:
		line_style.draw_cap(context, points[0], points[0].direction_to(points[1]), true)
		line_style.draw_cap(context, points[-1], points[-1].direction_to(points[-2]), false)
	
	#var half_decoration: float = Units.mm_to_px(decoration_size) * 0.5
	#var base: Vector2 = TICK_BASE * half_decoration
	#
	#for point: int in range(points.size() - 1):
		#
		#var delta: Vector2 = next_position - current_position
		#var line_length: float = delta.length()
		#var segment_count: int = int(line_length / segment_length)
		#
		#var step: Vector2 = delta * (segment_length / line_length)
		#
		#var decoration_position: Vector2 = current_position
		#
		#if decoration == DecorationType.SEGMENTED:
			#default_color = Color.TRANSPARENT
			#
			#draw_dashed_line(
				#current_position,
				#next_position,
				#color,
				#width,
				#decoration_size,
			#)
			#
			#if point > 0:
				#if joint_mode == LineJointMode.LINE_JOINT_SHARP:
					#var previous_point_position: Vector2 = get_point_position(point - 1)
					#draw_polyline(
						#PackedVector2Array([
							#current_position + current_position.direction_to(previous_point_position) * width,
							#current_position,
							#current_position + current_position.direction_to(next_position) * width,
						#]),
						#color,
						#width
					#)
				#elif joint_mode == LineJointMode.LINE_JOINT_ROUND:
					#draw_circle(
						#current_position,
						#width / 2.0,
						#color,
					#)
			#continue
		#else:
			#default_color = color
		#
		#for segment: int in segment_count:
			#decoration_position += step
			#match decoration:
				#DecorationType.NONE:
					#pass
				#
				#DecorationType.SEGMENTED:
					#pass
				#
				#DecorationType.DASH_DECORATION:
					#var angle: float = delta.angle()
					#var start: Vector2 = base.rotated(angle)
					#var end: Vector2 = -start
					#draw_line(
						#decoration_position + start,
						#decoration_position + end,
						#color,
						#width
					#)
				#
				#DecorationType.CIRCLE:
					#draw_circle(
						#decoration_position,
						#decoration_size,
						#color,
						#false,
						#width
					#)
	#
	#if decoration == DecorationType.SEGMENTED:
		#if begin_cap_mode == LineCapMode.LINE_CAP_BOX:
			#draw_line(
				#points[0],
				#points[0] + points[0].direction_to(points[1]) * -width / 2.0,
				#color,
				#width
			#)
		#elif begin_cap_mode == LineCapMode.LINE_CAP_ROUND:
			#draw_circle(
				#points[0],
				#width / 2.0,
				#color,
			#)
		#if end_cap_mode == LineCapMode.LINE_CAP_BOX:
			#draw_line(
				#points[-1],
				#points[-1] + points[-1].direction_to(points[-2]) * -width / 2.0,
				#color,
				#width
			#)
		#elif end_cap_mode == LineCapMode.LINE_CAP_ROUND:
			#draw_circle(
				#points[-1],
				#width / 2.0,
				#color,
			#)
	#
	#
	#if is_selected:
		#draw_polyline(
			#points,
			#ProjectColor.selection_values[ProjectColor.Selection.LINE],
			#width
		#)


func _validate_property(property: Dictionary) -> void:
	if property["name"] == &"width":
		property["hint_string"] = "suffix: mm"
		property["usage"] = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR


#region getters/setters
func set_segment_step(_segment_length: float) -> void:
	segment_length = maxf(0.01, _segment_length)
	changed.emit()
	queue_redraw()


func set_line_style(_line_style: LineStyle) -> void:
	if line_style.changed.is_connected(changed.emit):
		line_style.changed.disconnect(changed.emit)
	if line_style.changed.is_connected(queue_redraw):
		line_style.changed.disconnect(queue_redraw)
	
	line_style = _line_style
	if line_style._uses_builtin_line:
		default_color = color
	else:
		default_color = Color.TRANSPARENT
	line_style.changed.connect(changed.emit)
	line_style.changed.connect(queue_redraw)
	changed.emit()
	queue_redraw()


func set_line_decorations(_line_decorations: Array[LineDecoration]) -> void:
	for line_decoration: LineDecoration in line_decorations:
		if line_decoration.changed.is_connected(queue_redraw):
			line_decoration.changed.disconnect(queue_redraw)
	line_decorations = _line_decorations
	for line_decoration: LineDecoration in line_decorations:
		line_decoration.changed.connect(queue_redraw)
	queue_redraw()


func set_decoration_size(_decoration_size: float) -> void:
	decoration_size = _decoration_size
	changed.emit()
	queue_redraw()


func set_is_selected(_is_selected: bool) -> void:
	is_selected = _is_selected
	if is_selected:
		if line_style._uses_builtin_line:
			default_color = ProjectColor.selection_values[ProjectColor.Selection.LINE]
		if gizmos.is_empty():
			add_gizmos()
	else:
		if line_style._uses_builtin_line:
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


## Returns a list of possible editable properties.
func get_editable_properties() -> Array[Dictionary]:
	var editable_properties: Array[Dictionary]
	for property: Dictionary in get_property_list():
		if not EDITABLE_PROPERTIES_NAMES.has(property["name"]):
			continue
		editable_properties.append(property)
	return editable_properties


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


## Recalculates the bounding box of a line.
func _update_bounding_box() -> void:
	if points.size() < 2:
		bounding_box = Rect2()
		return
	bounding_box.position = points[0]
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


func _tool_add_line_decoration() -> void:
	EditorInterface.popup_quick_open(
		(func(path: String) -> void:
			var line_decoration: LineDecoration = load(path)
			var new_decorations: Array[LineDecoration] = line_decorations.duplicate()
			
			if new_decorations.has(line_decoration):
				return
			new_decorations.append(line_decoration)
			
			var undo_redo: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
			undo_redo.create_action("Add PolyLine2D LineDecoration")
			undo_redo.add_do_property(self, &"line_decorations", new_decorations)
			undo_redo.add_undo_property(self, &"line_decorations", line_decorations)
			undo_redo.commit_action()
			),
		["LineDecoration"]
		)


func _tool_remove_line_decoration() -> void:
	var confirmation_dialog: ConfirmationDialog = ConfirmationDialog.new()
	var decoratioins_container: VBoxContainer = VBoxContainer.new()
	
	confirmation_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	confirmation_dialog.title = "Remove LineDecorations"
	
	confirmation_dialog.canceled.connect(_on_remove_line_decoration_cancelled, CONNECT_APPEND_SOURCE_OBJECT)
	confirmation_dialog.confirmed.connect(_on_remove_line_decoration_confirmed, CONNECT_APPEND_SOURCE_OBJECT)
	
	get_tree().root.add_child(confirmation_dialog)
	confirmation_dialog.add_child(decoratioins_container)
	
	for line_decoration: LineDecoration in line_decorations:
		var check_box: CheckBox = CheckBox.new()
		check_box.text = line_decoration.resource_path.get_file().get_basename()
		check_box.set_meta(&"line_decoration", line_decoration)
		decoratioins_container.add_child(check_box)
	
	confirmation_dialog.size = Vector2.ZERO
	confirmation_dialog.show()


func _on_remove_line_decoration_cancelled(confirmation_dialog: ConfirmationDialog) -> void:
	confirmation_dialog.canceled.disconnect(_on_remove_line_decoration_cancelled)
	confirmation_dialog.confirmed.disconnect(_on_remove_line_decoration_confirmed)
	confirmation_dialog.queue_free()


func _on_remove_line_decoration_confirmed(confirmation_dialog: ConfirmationDialog) -> void:
	confirmation_dialog.canceled.disconnect(_on_remove_line_decoration_cancelled)
	confirmation_dialog.confirmed.disconnect(_on_remove_line_decoration_confirmed)
	
	var decoratioins_container: VBoxContainer = confirmation_dialog.get_child(0)
	var new_decorations: Array[LineDecoration] = line_decorations.duplicate()
	
	for child: Node in decoratioins_container.get_children():
		if child is not CheckBox:
			continue
		var check_box: CheckBox = child
		if not check_box.button_pressed:
			continue
		var line_decoration: LineDecoration = check_box.get_meta(&"line_decoration")
		if new_decorations.has(line_decoration):
			new_decorations.erase(line_decoration)
	
	var undo_redo: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Remove PolyLine2D LineDecoration")
	undo_redo.add_do_property(self, &"line_decorations", new_decorations)
	undo_redo.add_undo_property(self, &"line_decorations", line_decorations)
	undo_redo.commit_action()
	
	confirmation_dialog.queue_free()


func add_line_decoration(line_decoration: LineDecoration) -> void:
	if line_decorations.has(line_decoration):
		return
	line_decoration.changed.connect(queue_redraw)
	line_decorations.append(line_decoration)
	queue_redraw()


func remove_line_decoration(line_decoration: LineDecoration) -> void:
	if not line_decorations.has(line_decoration):
		return
	line_decoration.changed.disconnect(queue_redraw)
	line_decorations.erase(line_decoration)
	queue_redraw()
