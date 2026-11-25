@tool
class_name DashedLineStyle
extends LineStyleDefinition


@export var dash_size: float = 4.0: ## Dash size in mm.
	set = set_dash_size


func draw_segment(context: DrawLineContext, from: Vector2, to: Vector2) -> void:
	var dash_size_px: float = Units.mm_to_px(dash_size) * context.size_multiplier / 2
	if context is DrawEllipseContext:
		var ellipse_context: DrawEllipseContext = context
		_draw_dashed_ellipse(
			ellipse_context,
			dash_size_px,
		)
		return
	
	context.canvas_item.draw_dashed_line(
		from,
		to,
		context.color,
		context.width,
		dash_size_px,
		false,
		context.antialiased
	)
	var remaining_length: float = fmod(from.distance_to(to), dash_size_px)
	context.canvas_item.draw_line(
		to,
		to + to.direction_to(from) * remaining_length,
		context.color,
		context.width,
		context.antialiased
	)


func draw_joint(context: DrawLineContext, point: Vector2, dir_in: Vector2, dir_out: Vector2) -> void:
	if joint_mode == Line2D.LineJointMode.LINE_JOINT_ROUND:
		context.canvas_item.draw_circle(point, context.width * 0.5, context.color)
		return
	
	var cross: float = dir_in.cross(dir_out)
	if is_zero_approx(cross):
		return # Colinear segments
	
	var hw: float = context.width * 0.5
	var n_in: Vector2 = Vector2(-dir_in.y, dir_in.x)
	var n_out: Vector2 = Vector2(-dir_out.y, dir_out.x)
	var side: float = -1.0 if cross > 0.0 else 1.0
	
	var outer_in: Vector2 = point + n_in * hw * side
	var outer_out: Vector2 = point - n_out * hw * side
	
	if joint_mode == Line2D.LineJointMode.LINE_JOINT_BEVEL:
		context.canvas_item.draw_colored_polygon(
			PackedVector2Array([point, outer_in, outer_out]),
			context.color
		)
		return
	
	var t: float = (outer_out - outer_in).cross(dir_out) / cross
	var miter: Vector2 = outer_in + dir_in * t # TODO: Test if this event works, should draw miter when LINE_JOINT_SHARP
	
	context.canvas_item.draw_colored_polygon(
		PackedVector2Array([point, outer_in, miter]), context.color
	)
	context.canvas_item.draw_colored_polygon(
		PackedVector2Array([point, miter, outer_out]), context.color
	)


func draw_cap(context: DrawLineContext, point: Vector2, direction: Vector2, _is_begin: bool) -> void:
	if cap_mode == Line2D.LineCapMode.LINE_CAP_NONE:
		return
	if cap_mode == Line2D.LineCapMode.LINE_CAP_BOX:
		context.canvas_item.draw_line(
			point,
			point + direction * context.width / 2.0,
			context.color,
			context.width,
			context.antialiased
		)
		return
	context.canvas_item.draw_circle(point, context.width / 2.0, context.color)


func get_step() -> float:
	return dash_size


func set_dash_size(_dash_size: float) -> void:
	dash_size = _dash_size
	changed.emit()


func _draw_dashed_ellipse(
	context: DrawEllipseContext,
	dash_size_px: float,
) -> void:
	if dash_size_px <= 0.0 or context.major <= 0.0 or context.minor <= 0.0:
		return
	
	var sweep: float = context.end_angle - context.start_angle
	if absf(sweep) < 0.0001:
		return
	
	# 1. Build cumulative arc-length table over [start_angle, end_angle].
	var samples: int = 512
	var angles: PackedFloat32Array = PackedFloat32Array()
	var lengths: PackedFloat32Array = PackedFloat32Array()
	angles.resize(samples + 1)
	lengths.resize(samples + 1)
	angles[0] = context.start_angle
	
	var prev_pt: Vector2 = Ellipse.point_at(context.major, context.minor, context.start_angle)
	for i: int in range(1, samples + 1):
		var t: float = context.start_angle + sweep * float(i) / float(samples)
		var pt: Vector2 = Ellipse.point_at(context.major, context.minor, t)
		angles[i] = t
		lengths[i] = lengths[i - 1] + prev_pt.distance_to(pt)
		prev_pt = pt
	
	var total_length: float = lengths[samples]
	if total_length <= 0.0:
		return
	
	# 2. Snap dash+gap pairs only for a full ellipse so the ring closes
	#    cleanly. For an open arc we walk at the requested dash length so
	#    dash/gap spacing stays uniform end-to-end.
	var step: float
	var dash_count: int
	if context.closed:
		dash_count = maxi(1, roundi(total_length / (dash_size_px * 2.0)))
		step = total_length / float(dash_count * 2)
	else:
		step = dash_size_px
		dash_count = int(floori(total_length / (dash_size_px * 2.0)))
	
	var arc_points: int = maxi(4, ceili(step / 4.0))
	
	# 3. Draw each complete dash.
	for d: int in range(dash_count):
		var start_dist: float = float(d * 2) * step
		var end_dist: float = start_dist + step
		_draw_dash_arc(
			context.canvas_item,
			context.major,
			context.minor,
			context.color,
			context.width,
			context.antialiased,
			start_dist,
			end_dist,
			angles,
			lengths,
			samples,
			arc_points
		)
	
	# 4. For open arcs, optionally draw a trailing partial dash (mirrors the
	#    straight-line behaviour which also draws the leftover at the end).
	if not context.closed:
		var consumed: float = float(dash_count) * 2.0 * step
		if consumed < total_length:
			var end_dist: float = minf(consumed + step, total_length)
			_draw_dash_arc(
				context.canvas_item,
				context.major,
				context.minor,
				context.color,
				context.width,
				context.antialiased,
				consumed,
				end_dist,
				angles,
				lengths,
				samples,
				arc_points
			)
	elif context.filled:
		context.canvas_item.draw_ellipse(
			Vector2.ZERO,
			context.major,
			context.minor,
			context.color,
			true,
			-1.0,
			context.antialiased
		)


func _draw_dash_arc(
	canvas_item: CanvasItem,
	major: float,
	minor: float,
	line_color: Color,
	line_width: float,
	antialiased: bool,
	start_dist: float,
	end_dist: float,
	angles: PackedFloat32Array,
	lengths: PackedFloat32Array,
	samples: int,
	arc_points: int
) -> void:
	if end_dist <= start_dist:
		return
	var a0: float = _angle_at_distance(start_dist, angles, lengths, samples)
	var a1: float = _angle_at_distance(end_dist, angles, lengths, samples)
	canvas_item.draw_ellipse_arc(
		Vector2.ZERO,
		major,
		minor,
		a0,
		a1,
		arc_points,
		line_color,
		line_width,
		antialiased
	)


func _angle_at_distance(
	dist: float,
	angles: PackedFloat32Array,
	lengths: PackedFloat32Array,
	samples: int
) -> float:
	if dist <= 0.0:
		return angles[0]
	if dist >= lengths[samples]:
		return angles[samples]
	var idx: int = lengths.bsearch(dist)
	if idx <= 0:
		return angles[0]
	if idx > samples:
		return angles[samples]
	var s0: float = lengths[idx - 1]
	var s1: float = lengths[idx]
	var w: float = (dist - s0) / maxf(s1 - s0, 0.00001)
	return lerpf(angles[idx - 1], angles[idx], w)
