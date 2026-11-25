@abstract @tool
class_name LineStyleDefinition
extends Resource


@export var joint_mode: Line2D.LineJointMode:
	set = set_joint_mode
@export var cap_mode: Line2D.LineCapMode:
	set = set_cap_mode


@abstract func draw_segment(context: DrawLineContext, from: Vector2, to: Vector2) -> void


@warning_ignore("unused_parameter")
func draw_joint(context: DrawLineContext, point: Vector2, dir_in: Vector2, dir_out: Vector2) -> void:
	pass


## [param direction] points away from the line body. [param is_begin] is true
## for the first point, false for the last.
@warning_ignore("unused_parameter")
func draw_cap(context: DrawLineContext, point: Vector2, direction: Vector2, is_begin: bool) -> void:
	pass


## Spacing for decorations in mm. [code]0.0[/code] = use [PolyLine2D]'s fallback.
func get_step() -> float:
	return 0.0


func set_joint_mode(_joint_mode: Line2D.LineJointMode) -> void:
	joint_mode = _joint_mode
	changed.emit()


func set_cap_mode(_cap_mode: Line2D.LineCapMode) -> void:
	cap_mode = _cap_mode
	changed.emit()
