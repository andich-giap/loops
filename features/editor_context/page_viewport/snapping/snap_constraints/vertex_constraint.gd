class_name VertexConstraint
extends SnapConstraint


func get_snap(
	mouse_position: Vector2,
	context_nodes: Array[Node],
	zoom_factor: float
) -> SnapReceipt:
	if not is_enabled:
		return _get_faulty_receipt(mouse_position)
	var receipt: SnapReceipt
	var positions: PackedVector2Array
	
	for node: Node in context_nodes:
		if node is PolyLine2D:
			var poly_line_2d: PolyLine2D = node
			for point: Vector2 in poly_line_2d.points:
				positions.append(point + poly_line_2d.position)
		else:
			var position: Vector2 = node.get(&"position")
			positions.append(position)
	
	if positions.is_empty():
		return _get_faulty_receipt(mouse_position)
	
	var best_position: Vector2 = positions[0]
	var closest_distance: float = positions[0].distance_to(mouse_position)
	for position: Vector2 in positions:
		var distance: float = position.distance_to(mouse_position)
		if distance < closest_distance:
			best_position = position
			closest_distance = distance
	
	var distance_in_screen_pixels: float = closest_distance * zoom_factor
	var is_within_radius: bool = distance_in_screen_pixels <= grab_radius_pixels
	
	if not is_within_radius:
		return _get_faulty_receipt(best_position)
	
	receipt = SnapReceipt.new(
		best_position,
		Type.VERTEX,
		mouse_position,
		is_within_radius
	)
	return receipt
