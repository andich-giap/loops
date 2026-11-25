@tool
class_name CircleLineDecoration
extends LineDecoration


@export var filled: bool = false:
	set = set_filled


func draw_decoration(
	context: DrawLineContext,
	position: Vector2,
	_tangent: Vector2,
	_normal: Vector2,
	step_index: int,
) -> void:
	if not should_draw(step_index):
		return
	
	var radius_px: float = Units.mm_to_px(base_size) * context.size_multiplier

	context.canvas_item.draw_circle(
		position,
		radius_px,
		context.color,
		filled,
		context.width,
		context.antialiased
	)


func set_filled(_filled: bool) -> void:
	filled = _filled
	changed.emit()
