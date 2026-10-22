@abstract @tool
class_name LineStyle
extends Resource


## If true, [PolyLine2D] lets the built-in [Line2D] renderer draw the line
## (and keeps [member Line2D.default_color] as-is). Set in [method _init].
var _uses_builtin_line: bool


func _init() -> void:
	_uses_builtin_line = false


@abstract func draw_segment(context: DrawLineContext, from: Vector2, to: Vector2) -> void


@warning_ignore("unused_parameter")
func draw_joint(context: DrawLineContext, point: Vector2, dir_in: Vector2, dir_out: Vector2) -> void:
	pass


## [param direction] points away from the line body. [param is_begin] is true
## for the first point, false for the last.
@warning_ignore("unused_parameter")
func draw_cap(context: DrawLineContext, point: Vector2, direction: Vector2, is_begin: bool) -> void:
	pass


## Spacing for decorations. [code]0.0[/code] = use [PolyLine2D]'s fallback.
func get_step() -> float:
	return 0.0
