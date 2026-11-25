@tool
class_name SolidLineStyle
extends LineStyleDefinition


func draw_segment(context: DrawLineContext, from: Vector2, to: Vector2) -> void:
	if context is DrawEllipseContext:
		var ellipse_context: DrawEllipseContext = context
		ellipse_context.canvas_item.draw_ellipse_arc(
			Vector2.ZERO,
			ellipse_context.major,
			ellipse_context.minor,
			ellipse_context.start_angle,
			ellipse_context.end_angle,
			128,
			ellipse_context.color,
			ellipse_context.width,
			ellipse_context.antialiased
		)
		if ellipse_context.filled:
			if ellipse_context.closed:
				ellipse_context.canvas_item.draw_ellipse(
					Vector2.ZERO,
					ellipse_context.major,
					ellipse_context.minor,
					ellipse_context.color,
					true,
					-1.0,
					ellipse_context.antialiased
				)
		
		return
	
	context.canvas_item.draw_line(
		from,
		to,
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
