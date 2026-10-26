@tool
class_name TickLineDecoration
extends LineDecoration


@export var width_scale: float = 1.0


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
		context.width,
		context.antialiased
	)
