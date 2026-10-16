@abstract
class_name SnapConstraint
extends RefCounted


enum Type {
	NONE,
	GRID,
	VERTEX,
	MIDPOINT,
}
var is_enabled: bool = true ## Determines if constraint will be used by [SnapEngine].
var priority: int = 0 ## Determines the order in which results of [SnapEngine] will be sorted.
var grab_radius_pixels: float = 12.0 ## Screen-space tolerance for catching a snap point.


## Calculates the snap position.
@abstract func get_snap(
	mouse_position: Vector2,
	context_nodes: Array[Node],
	zoom_factor: float
) -> SnapReceipt


func _get_faulty_receipt(mouse_position: Vector2) -> SnapReceipt:
	return SnapReceipt.new(
		mouse_position,
		Type.NONE,
		mouse_position,
		false
	)
