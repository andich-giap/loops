@tool
class_name TickLineDecoration
extends LineDecoration


@export var width_scale: float = 1.0:
	set = set_width_scale


func draw_decoration(
	context: DrawLineContext,
	position: Vector2,
	tangent: Vector2,
	normal: Vector2,
	step_index: int,
) -> void:
	if not should_draw(step_index):
		return
	
	var tick_length_px: float = Units.mm_to_px(base_size) * context.size_multiplier
	
	var from: Vector2 = position - (tangent - normal) * tick_length_px
	var to: Vector2 = position + (tangent - normal) * tick_length_px
	
	context.canvas_item.draw_line(
		from,
		to,
		context.color,
		context.width * width_scale,
		context.antialiased
	)


func set_width_scale(_width_scale: float) -> void:
	width_scale = maxf(0.0, _width_scale)
	changed.emit()
