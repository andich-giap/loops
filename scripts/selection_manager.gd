class_name SelectionManager
extends Control


signal selected(selected_nodes: Array[Node])
var can_select: bool = true
var is_selecting: bool = false:
	set = set_is_selecting
var selection_rect: Rect2
var clear_on_new_selection: bool = true
@onready var contents_layer: CanvasLayer = $"../../ContentsLayer"


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and can_select:
			
			if mouse_button_event.is_pressed():
				is_selecting = true
				selection_rect.position = get_local_mouse_position()
			else:
				if clear_on_new_selection \
					and not (mouse_button_event.get_modifiers_mask() & KEY_MASK_SHIFT) == KEY_MASK_SHIFT:
					clear_selection()
				is_selecting = false
				queue_redraw()
	
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
	var selected_nodes: Array[Node] = []
	for node: Node in contents_layer.get_children():
		if node is not CanvasItem:
			continue
		var node_rect: Rect2 = get_node_rect(node)
		if node_rect.intersects(selection_rect.abs()):
			node.add_to_group("selection")
			if node.has_method("add_to_selection"):
				node.call("add_to_selection")
			selected_nodes.append(node)
	if not selected_nodes.is_empty():
		selected.emit(selected_nodes)
	selection_rect.size = Vector2.ZERO


func get_node_rect(node: Node) -> Rect2:
	var rect: Rect2
	if node is PolyLine2D:
		var poly_line_2d: PolyLine2D = node
		return poly_line_2d.bounding_box
	return rect


func clear_selection() -> void:
	get_tree().call_group("selection", "remove_from_selection")
