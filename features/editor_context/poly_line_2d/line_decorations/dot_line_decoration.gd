@tool
class_name DotLineDecoration
extends LineDecoration


func draw_decoration(
	context: DrawLineContext,
	position: Vector2,
	_tangent: Vector2,
	_normal: Vector2,
	step_index: int,
) -> void:
	if not should_draw(step_index):
		return
	
	context.canvas_item.draw_circle(
		position,
		context.width / 2.0,
		context.color,
		true,
		context.width,
		context.antialiased
	)


func _validate_property(property: Dictionary) -> void:
	if property[&"name"] == &"base_size":
		property[&"usage"] = PROPERTY_USAGE_NO_EDITOR
