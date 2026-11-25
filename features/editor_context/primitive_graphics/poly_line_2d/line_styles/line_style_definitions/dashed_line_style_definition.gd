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
			ellipse_context.canvas_item,
			ellipse_context.major,
			ellipse_context.minor,
			dash_size_px,
			ellipse_context.width,
			ellipse_context.color,
			ellipse_context.antialiased
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
	canvas_item: CanvasItem,
	major: float,
	minor: float,
	dash_length: float,
	line_width: float,
	line_color: Color,
	antialiased: bool
) -> void:
	if dash_length <= 0.0 or major <= 0.0 or minor <= 0.0:
		return
	# 1. Build cumulative arc-length table mapped to parametric angle t
	var samples: int = 512
	var angles: PackedFloat32Array = PackedFloat32Array()
	var lengths: PackedFloat32Array = PackedFloat32Array()
	angles.resize(samples + 1)
	lengths.resize(samples + 1)
	
	var prev_pt: Vector2 = Vector2(major, 0.0)
	
	for i: int in range(1, samples + 1):
		var t: float = TAU * float(i) / float(samples)
		var pt: Vector2 = Vector2(major * cos(t), minor * sin(t))
		angles[i] = t
		lengths[i] = lengths[i - 1] + prev_pt.distance_to(pt)
		prev_pt = pt
	
	var total_length: float = lengths[samples]
	
	# 2. Snap dash length so dash+gap pairs close the loop cleanly
	var dash_count: float = maxi(1, roundi(total_length / (dash_length * 2.0)))
	var step: float = total_length / float(dash_count * 2)
	var arc_points: int = maxi(4, ceili(step / 4.0))

	# 3. Interpolate start/end angles for each dash and draw the curved arc
	for d: int in range(dash_count):
		var start_dist: float = float(d * 2) * step
		var end_dist: float = start_dist + step

		var i0: float = lengths.bsearch(start_dist)
		var a0: float = 0.0
		if i0 >= samples:
			a0 = TAU
		elif i0 > 0:
			var w0: float = (start_dist - lengths[i0 - 1]) / maxf(lengths[i0] - lengths[i0 - 1], 0.00001)
			a0 = lerpf(angles[i0 - 1], angles[i0], w0)

		var i1: float = lengths.bsearch(end_dist)
		var a1: float = 0.0
		if i1 >= samples:
			a1 = TAU
		elif i1 > 0:
			var w1: float = (end_dist - lengths[i1 - 1]) / maxf(lengths[i1] - lengths[i1 - 1], 0.00001)
			a1 = lerpf(angles[i1 - 1], angles[i1], w1)
		
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
