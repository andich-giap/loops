class_name SnapReceipt
extends RefCounted


var snapped_position: Vector2 ## Final position. Falls back to [member mouse_position] if [member snap_successfull] is [code]false[/code].
var snap_type: SnapConstraint.Type ## Used for drawing the snap graphics.
var mouse_position: Vector2 ## Local mouse position.
var snap_successful: bool ## Determines if the snap was successful or not.
var snapped_position_canvas_space: Vector2 ## Set manually like such: [code]canvas_transform * receipt.snapped_position[/code].


func _init(
	_snapped_position: Vector2,
	_snap_type: SnapConstraint.Type,
	_mouse_position: Vector2,
	_snap_successful: bool = true
) -> void:
	snapped_position = _snapped_position
	snap_type = _snap_type
	mouse_position = _mouse_position
	snap_successful = _snap_successful
