@abstract @tool
class_name LineDecoration
extends Resource


@export var base_size: float = 1.0 ## Base size in mm.
@export var period_step: int = 1: ## Draw when [code](step_index - phase) % period_step == 0[/code].
	set = set_period_step
@export var phase: int = 0: ## First step of the period. Clamped to [code][0, period_step - 1][/code].
	set = set_phase
@export var position_offset: float = 0.0 ## Offset along the tangent, in mm.


@abstract func draw_decoration(
	context: DrawLineContext,
	position: Vector2,
	tangent: Vector2,
	normal: Vector2,
	step_index: int,
) -> void


func should_draw(step_index: int) -> bool:
	return (step_index - phase) % period_step == 0


func set_period_step(_period_step: int) -> void:
	period_step = maxi(1, _period_step)
	set_phase(phase)


func set_phase(_phase: int) -> void:
	phase = clampi(_phase, 0, period_step - 1)
