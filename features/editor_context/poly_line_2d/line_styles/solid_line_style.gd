@tool
class_name SolidLineStyle
extends LineStyle


func _init() -> void:
	_uses_builtin_line = true


@warning_ignore("unused_parameter")
func draw_segment(context: DrawLineContext, from: Vector2, to: Vector2) -> void:
	pass


@warning_ignore("unused_parameter")
func draw_joint(context: DrawLineContext, point: Vector2, dir_in: Vector2, dir_out: Vector2) -> void:
	pass


@warning_ignore("unused_parameter")
func draw_cap(context: DrawLineContext, point: Vector2, direction: Vector2, is_begin: bool) -> void:
	pass
