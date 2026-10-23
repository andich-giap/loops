@tool
class_name CircleLineDecoration
extends LineDecoration


@export var filled: bool = false:
	set = set_filled


@warning_ignore("unused_parameter")
func draw_decoration(
	context: DrawLineContext,
	position: Vector2,
	tangent: Vector2,
	normal: Vector2,
	step_index: int,
) -> void:
	if not should_draw(step_index):
		return
	context.canvas_item.draw_circle(
		position + tangent * position_offset,
		base_size * context.size_multiplier,
		context.color,
		filled,
		context.width,
		context.antialiased
	)


func set_filled(_filled: bool) -> void:
	filled = _filled
	changed.emit()
