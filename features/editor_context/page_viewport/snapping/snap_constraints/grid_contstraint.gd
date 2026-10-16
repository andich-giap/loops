class_name GridConstraint
extends SnapConstraint


var grid: Grid


func _init(_grid: Grid) -> void:
	grid = _grid


func get_snap(
	mouse_position: Vector2,
	_context_nodes: Array[Node],
	_zoom_factor: float
) -> SnapReceipt:
	if not is_instance_valid(grid) or not grid.visible or not is_enabled:
		return _get_faulty_receipt(mouse_position)
	var interval_px: float = grid.interval
	var interval: Vector2 = Vector2(Units.mm_to_px(interval_px), Units.mm_to_px(interval_px))
	var snap_position: Vector2 = snapped(mouse_position, interval)
	var receipt: SnapReceipt = SnapReceipt.new(
		snap_position,
		Type.GRID,
		mouse_position,
	)
	return receipt
