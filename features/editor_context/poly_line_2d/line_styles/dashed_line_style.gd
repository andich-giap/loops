@tool
class_name DashedLineStyle
extends LineStyle


@export var dash_size: float = 4.0: ## Dash size in mm.
	set = set_dash_size
@export var joint_mode: Line2D.LineJointMode:
	set = set_joint_mode
@export var cap_mode: Line2D.LineCapMode:
	set = set_cap_mode



func draw_segment(context: DrawLineContext, from: Vector2, to: Vector2) -> void:
	context.canvas_item.draw_dashed_line(
		from,
		to,
		context.color,
		context.width,
		Units.mm_to_px(dash_size),
		true,
		context.antialiased
	)


func draw_joint(context: DrawLineContext, point: Vector2, dir_in: Vector2, dir_out: Vector2) -> void:
	if joint_mode == Line2D.LineJointMode.LINE_JOINT_SHARP:
		var points: PackedVector2Array = PackedVector2Array([
			point + dir_in * context.width / 2.0,
			point,
			point + dir_out * context.width / 2.0,
		])
		context.canvas_item.draw_polyline(
			points,
			context.color,
			context.width,
			context.antialiased
		)
	
	elif joint_mode == Line2D.LineJointMode.LINE_JOINT_BEVEL:
		var cross: float = dir_in.cross(dir_out)
		
		# If the segments are collinear.
		if is_zero_approx(cross):
			return

		var half_width: float = context.width * 0.5
		
		# Calculate the normals
		var normal_in: Vector2 = Vector2(-dir_in.y, dir_in.x)
		var normal_out: Vector2 = Vector2(-dir_out.y, dir_out.x)
		
		# Flip the normals if it's a left turn
		var side: float = -1.0 if cross > 0.0 else 1.0
		
		var point_in: Vector2 = point + normal_in * half_width * side
		var point_out: Vector2 = point - normal_out * half_width * side
		
		context.canvas_item.draw_colored_polygon(
			PackedVector2Array([point, point_in, point_out]),
			context.color
		)
		context.canvas_item.draw_line(
			point,
			point + dir_in * half_width,
			context.color,
			context.width,
			context.antialiased
		)
	
	else:
		context.canvas_item.draw_circle(
			point,
			context.width / 2.0,
			context.color
		)


func draw_cap(context: DrawLineContext, point: Vector2, direction: Vector2, _is_begin: bool) -> void:
	if cap_mode == Line2D.LineCapMode.LINE_CAP_NONE:
		pass
	elif cap_mode == Line2D.LineCapMode.LINE_CAP_BOX:
		context.canvas_item.draw_line(
			point,
			point - direction * context.width / 2.0,
			context.color,
			context.width,
			context.antialiased
		)
	else:
		context.canvas_item.draw_circle(
			point,
			context.width / 2.0,
			context.color
		)


func get_step() -> float:
	return dash_size


func set_dash_size(_dash_size: float) -> void:
	dash_size = _dash_size
	changed.emit()


func set_joint_mode(_joint_mode: Line2D.LineJointMode) -> void:
	joint_mode = _joint_mode
	changed.emit()


func set_cap_mode(_cap_mode: Line2D.LineCapMode) -> void:
	cap_mode = _cap_mode
	changed.emit()
