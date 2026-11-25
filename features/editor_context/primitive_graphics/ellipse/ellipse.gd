@tool @icon("res://addons/at-icons/node2d/mesh_circle.svg")
class_name Ellipse
extends PrimitiveGraphics2D


@export_custom(PROPERTY_HINT_NONE, "suffix:mm") var major: float = 16:
	set = set_major
@export_custom(PROPERTY_HINT_NONE, "suffix:mm") var minor: float = 16:
	set = set_minor
@export var filled: bool = false
var _arc_table: Dictionary = {}
var _arc_table_key: Vector2 = Vector2.INF


func _init() -> void:
	if width == 10.0:
		width = Units.mm_to_px(0.5)


func _draw() -> void:
	_draw_debug_bounding_box()
	var major_px: float = Units.mm_to_px(major)
	var minor_px: float = Units.mm_to_px(minor)
	
	var context: DrawEllipseContext = DrawEllipseContext.new()
	context.canvas_item = self
	if is_selected:
		context.color = ProjectColor.selection_values[ProjectColor.Selection.LINE]
	else:
		context.color = color
	context.size_multiplier = decoration_size
	if filled:
		context.width = -1.0
	else:
		context.width = width
	context.major = major_px
	context.minor = minor_px
	context.filled = filled
	
	line_style.line_style_definition.draw_segment(
		context,
		Vector2.ZERO,
		Vector2.ZERO
	)
	if not line_style.line_decorations.is_empty():
		_draw_decorations(context, major_px, minor_px)


#region setters/getters
func set_major(_major: float) -> void:
	major = _major
	_update_bounding_box()
	queue_redraw()


func set_minor(_minor: float) -> void:
	minor = _minor
	_update_bounding_box()
	queue_redraw()
#endregion


func get_perimeter(_major: float = major, _minor: float = minor) -> float:
	var h: float = pow(_major - _minor, 2) / pow(_major + _minor, 2)
	var perimeter: float = PI * (_major + _minor) * (1.0 + (3.0 * h) / (10.0 + sqrt(4.0 - 3.0 * h)))
	return perimeter


static func point_at(a: float, b: float, t: float) -> Vector2:
	return Vector2(a * cos(t), b * sin(t))


## Tangent at parametric parameter t
static func tangent_at_parameter(a: float, b: float, t: float) -> Vector2:
	return Vector2(-a * sin(t), b * cos(t)).normalized()


## Outward normal at parametric parameter t
static func normal_at_parameter(a: float, b: float, t: float) -> Vector2:
	return Vector2(b * cos(t), a * sin(t)).normalized()


## Tangent at an actual point on the ellipse
static func tangent_at_point(a: float, b: float, p: Vector2) -> Vector2:
	return Vector2(-p.y * a * a, p.x * b * b).normalized()


## Outward normal at an actual point on the ellipse
static func normal_at_point(a: float, b: float, p: Vector2) -> Vector2:
	return Vector2(p.x / (a * a), p.y / (b * b)).normalized()


## Returns a list of possible editable properties.
func get_editable_properties() -> Array[Dictionary]:
	var property_names: Array[StringName] = EDITABLE_PROPERTIES_NAMES.duplicate()
	property_names.erase(&"closed")
	property_names.append_array([&"major", &"minor", &"resolution"])
	var editable_properties: Array[Dictionary]
	for property: Dictionary in get_property_list():
		if not property_names.has(property["name"]):
			continue
		editable_properties.append(property)
	return editable_properties


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


## Creates gizmos.
func add_gizmos() -> void:
	pass


## Removes gizmos.
func remove_gizmos() -> void:
	pass


func handle_selection_query(
	_query: SelectionQuery,
	receipt: SelectionReceipt,
	selection_rect: Rect2
) -> void:
	var points: PackedVector2Array = build_ellipse(
		Units.mm_to_px(major),
		Units.mm_to_px(minor),
		rotation
	)
	for point: int in range(points.size()):
		points[point] = points[point] + position
	
	var intersection: Array[PackedVector2Array] = Geometry2D.intersect_polyline_with_polygon(
		points,
		SelectionManager.rect2_to_packed_vector2_array(selection_rect)
		)
	if not intersection.is_empty():
		receipt.selected_nodes.append(self)


func _update_bounding_box() -> void:
	var major_px: float = Units.mm_to_px(major)
	var minor_px: float = Units.mm_to_px(minor)
	bounding_box = Rect2(
		-major_px,
		-minor_px,
		 major_px * 2.0,
		 minor_px * 2.0
	)


func build_ellipse(
	major_radius: float,
	minor_radius: float,
	ellipse_rotation: float = 0.0,
	segments: int = 64
) -> PackedVector2Array:
	segments = max(segments, 3)
	var points: PackedVector2Array = PackedVector2Array()
	points.resize(segments)
	
	var cos_rot: float = cos(ellipse_rotation)
	var sin_rot: float = sin(ellipse_rotation)
	
	for i: int in segments:
		var t: float = TAU * float(i) / float(segments)
		var x: float = major_radius * cos(t)
		var y: float = minor_radius * sin(t)
		
		var rx: float = x * cos_rot - y * sin_rot
		var ry: float = x * sin_rot + y * cos_rot
		
		points[i] = Vector2(rx, ry)
	
	return points


func _draw_decorations(context: DrawEllipseContext, a: float, b: float) -> void:
	var table: Dictionary = _get_arc_length_table(a, b)
	var total_length: float = table.total
	if total_length <= 0.0:
		return

	var step_mm: float = line_style.line_style_definition.get_step()
	var step_px: float = Units.mm_to_px(step_mm if step_mm > 0.0 else segment_length)
	step_px *= decoration_size
	if step_px <= 0.0:
		return

	# Snap the step so the decoration ring closes cleanly (a closed ellipse
	# needs N·step == perimeter — same trick DashedLineStyle uses for dashes).
	var count: int = maxi(1, roundi(total_length / step_px))
	var actual_step: float = total_length / float(count)

	# Half-step phase keeps the spacing symmetric around t = 0.
	# (PolyLine2D uses 3/4-step phase; pick whichever you prefer visually.)
	var phase: float = actual_step * 0.75

	for line_decoration: LineDecoration in line_style.line_decorations:
		var offset_px: float = Units.mm_to_px(line_decoration.position_offset)
		for i: int in count:
			var distance: float = phase + float(i) * actual_step
			var t: float = _angle_at_arc_length(distance, table)
			var pos: Vector2 = point_at(a, b, t)
			var tangent: Vector2 = tangent_at_parameter(a, b, t)
			var normal: Vector2 = normal_at_parameter(a, b, t)
			var final_position: Vector2 = pos + tangent * offset_px
			line_decoration.draw_decoration(context, final_position, tangent, normal, i)


func _build_arc_length_table(a: float, b: float, samples: int = 256) -> Dictionary:
	var angles: PackedFloat32Array = PackedFloat32Array()
	var lengths: PackedFloat32Array = PackedFloat32Array()
	angles.resize(samples + 1)
	lengths.resize(samples + 1)
	angles[0] = 0.0
	lengths[0] = 0.0

	var prev: Vector2 = point_at(a, b, 0.0)
	for i: int in range(1, samples + 1):
		var t: float = TAU * float(i) / float(samples)
		var pt: Vector2 = point_at(a, b, t)
		angles[i] = t
		lengths[i] = lengths[i - 1] + prev.distance_to(pt)
		prev = pt

	return {"angles": angles, "lengths": lengths, "total": lengths[samples]}


func _angle_at_arc_length(s: float, table: Dictionary) -> float:
	var angles: PackedFloat32Array = table.angles
	var lengths: PackedFloat32Array = table.lengths
	var total: float = table.total

	s = fposmod(s, total)
	var idx: int = lengths.bsearch(s) # first index where lengths[idx] >= s
	if idx <= 0:
		return 0.0
	if idx >= lengths.size():
		return TAU

	var s0: float = lengths[idx - 1]
	var s1: float = lengths[idx]
	var w: float = (s - s0) / maxf(s1 - s0, 0.00001)
	return lerpf(angles[idx - 1], angles[idx], w)


func _get_arc_length_table(a: float, b: float) -> Dictionary:
	var key: Vector2 = Vector2(a, b)
	if _arc_table_key == key and not _arc_table.is_empty():
		return _arc_table
	_arc_table = _build_arc_length_table(a, b)
	_arc_table_key = key
	return _arc_table
