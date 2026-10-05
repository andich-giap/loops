@tool
class_name DeviceGraphics
extends Node2D


var RADIUS: float = Units.mm_to_px(5.0)
@export var width: float = 0.0:
	set = set_width
@export var thickness: float = 1.0:
	set = set_thickness
@export var resolution: int = 16:
	set = set_resolution


#region virtual methods
func _draw() -> void:
	draw_arc(Vector2( width, 0.0), RADIUS, -PI/2,   PI/2, resolution, Color.WHITE, thickness)
	draw_arc(Vector2(-width, 0.0), RADIUS,  PI/2, 3*PI/2, resolution, Color.WHITE, thickness)
#endregion


#region setters and getters
func set_width(_width: float) -> void:
	width = maxf(_width, 0.0)
	queue_redraw()


func set_thickness(_thickness: float) -> void:
	thickness = maxf(_thickness, 0.0)
	queue_redraw()


func set_resolution(_resolution: int) -> void:
	resolution = _resolution
	queue_redraw()
#endregion
