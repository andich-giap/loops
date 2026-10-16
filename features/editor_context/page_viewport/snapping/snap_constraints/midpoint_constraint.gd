class_name MidpointConstraint
extends SnapConstraint


func get_snap(
	mouse_position: Vector2,
	context_nodes: Array[Node],
	zoom_factor: float
) -> SnapReceipt:
	if not is_enabled:
		return SnapReceipt.new(mouse_position, Type.NONE, mouse_position, false)
	
	var midpoints: PackedVector2Array = PackedVector2Array()
	
	for node: Node in context_nodes:
		if node is PolyLine2D:
			var poly_line: PolyLine2D = node
			var points_count: int = poly_line.points.size()
			
			if points_count < 2:
				continue
			
			for i: int in range(points_count - 1):
				var point_1: Vector2 = poly_line.points[i] + poly_line.position
				var point_2: Vector2 = poly_line.points[i + 1] + poly_line.position
				var mid: Vector2 = (point_1 + point_2) / 2.0
				midpoints.append(mid)
	
	if midpoints.is_empty():
		return SnapReceipt.new(mouse_position, Type.NONE, mouse_position, false)
	
	var best_position: Vector2 = midpoints[0]
	var closest_distance: float = best_position.distance_to(mouse_position)
	
	for midpoint: Vector2 in midpoints:
		var distance: float = midpoint.distance_to(mouse_position)
		if distance < closest_distance:
			best_position = midpoint
			closest_distance = distance
	
	var distance_in_screen_pixels: float = closest_distance * zoom_factor
	var is_within_radius: bool = distance_in_screen_pixels <= grab_radius_pixels
	
	if not is_within_radius:
		return _get_faulty_receipt(best_position)
	
	return SnapReceipt.new(
		best_position,
		Type.MIDPOINT,
		mouse_position,
		is_within_radius
	)
