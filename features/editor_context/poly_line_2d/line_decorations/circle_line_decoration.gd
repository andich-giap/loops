@tool
class_name CircleLineDecoration
extends LineDecoration


@export var filled: bool = false


func draw_decoration(
	context: DrawLineContext,
	position: Vector2,
	tangent: Vector2,
	normal: Vector2,
	step_index: int,
) -> void:
	context.canvas_item.draw_circle(
		position,
		base_size * context.size_multiplier,
		context.color,
		filled,
		context.width,
		context.antialiased
	)


func should_draw(step_index: int) -> bool:
	return (step_index - phase) % period_step == 0


func set_period_step(_period_step: int) -> void:
	period_step = maxi(1, _period_step)
	set_phase(phase)


func set_phase(_phase: int) -> void:
	phase = clampi(_phase, 0, period_step - 1)
