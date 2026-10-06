class_name SelectionManager
extends Control


signal selected(selected_nodes: Array[Node])
static var can_select: bool = true
var is_selecting: bool = false:
	set = set_is_selecting
var selection_rect: Rect2
var single_click_size: float = 3.0
var clear_on_new_selection: bool = true
var contents_layer: CanvasLayer


func _gui_input(event: InputEvent) -> void:
	if not can_select:
		is_selecting = false
		return
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and can_select:
			if mouse_button_event.is_pressed():
				is_selecting = true
				selection_rect.position = get_local_mouse_position()
			else:
				if selection_rect.size.is_zero_approx():
					selection_rect.position = get_local_mouse_position() - Vector2(single_click_size, single_click_size) / 2.0
					selection_rect.size = Vector2(single_click_size, single_click_size)
				var selected_nodes: Array[Node] = get_selection(selection_rect)
				if selected_nodes.is_empty() \
					or (clear_on_new_selection \
					and not (mouse_button_event.get_modifiers_mask() & KEY_MASK_SHIFT) == KEY_MASK_SHIFT):
					clear_selection()
				is_selecting = false
				queue_redraw()
				return
	
	if event is InputEventMouseMotion and is_selecting:
		selection_rect.end = get_local_mouse_position()
		queue_redraw()


func _draw() -> void:
	if not is_selecting:
		return
	draw_rect(
		selection_rect,
		ProjectColor.selection_values[ProjectColor.Selection.AREA],
		true)


func set_is_selecting(_is_selecting: bool) -> void:
	is_selecting = _is_selecting
	if is_selecting:
		return
	var selected_nodes: Array[Node] = get_selection(selection_rect)
	for node: Node in selected_nodes:
		add_to_selection(node)
	if not selected_nodes.is_empty():
		selected.emit(selected_nodes)
	selection_rect.size = Vector2.ZERO


func get_selection(_selection_rect: Rect2) -> Array[Node]:
	var selected_nodes: Array[Node] = []
	for node: Node in contents_layer.get_children():
		if node is not CanvasItem:
			continue
		var node_rect: Rect2 = get_node_rect(node)
		if node_rect.intersects(_selection_rect.abs()):
			if node is PolyLine2D:
				var poly_line_2d: PolyLine2D = node
				var intersection: Array[PackedVector2Array] = Geometry2D.intersect_polyline_with_polygon(
					poly_line_2d.points,
					rect2_to_packed_vector2_array(_selection_rect)
					)
				if not intersection.is_empty():
					selected_nodes.append(node)
				continue
			selected_nodes.append(node)
	return selected_nodes


static func rect2_to_packed_vector2_array(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	])


func add_to_selection(node: Node) -> void:
	node.add_to_group("selection")
	if node.has_method("add_to_selection"):
		node.call("add_to_selection")


func get_node_rect(node: Node) -> Rect2:
	var rect: Rect2
	if node is PolyLine2D:
		var poly_line_2d: PolyLine2D = node
		return poly_line_2d.bounding_box
	if node is LLineEdit:
		var l_line_edit: LLineEdit = node
		rect = l_line_edit.get_rect()
	return rect


func clear_selection() -> void:
	get_tree().call_group("selection", "remove_from_selection")
