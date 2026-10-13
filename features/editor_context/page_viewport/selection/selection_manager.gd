class_name SelectionManager
extends Control
## Manages Users input for selecting page contents in [PageViewport].


signal selection_changed(receipt: SelectionReceipt) ## Emitted if after finishing the selection there are valid contents.
var can_select: bool = true ## Determines if selection manager listens to User input.
var is_selecting: bool = false: ## Determines if there is selection in progress.
	set = set_is_selecting
var selection_rect: Rect2 ## Current [Rect2] of the selection.
var single_click_size: float = 3.0 ## The size of the selection rect on a single click.
var clear_on_new_selection: bool = true ## If [code]true[/code] when starting the new selection previous selection is cleared unless [kbd]Shift[/kbd] is pressed.
var contents_layer: CanvasLayer ## Reference to the layer with the contents.
var _query: SelectionQuery ## Current [SelectionQuery].
var _selection_receipt: SelectionReceipt = SelectionReceipt.new() ## Current selection.


func _draw() -> void:
	if not is_selecting:
		return
	draw_rect(
		selection_rect,
		ProjectColor.selection_values[ProjectColor.Selection.AREA],
		true)


#region setters/getters
func set_is_selecting(_is_selecting: bool) -> void:
	is_selecting = _is_selecting
	if is_selecting:
		return
	_get_interactive_selection()
#endregion


## Returns the array containing the nodes that are under a [param _selection_rect].
func get_selection(query: SelectionQuery, _selection_rect: Rect2) -> SelectionReceipt:
	var selection_receipt: SelectionReceipt = SelectionReceipt.new()
	for node: Node in contents_layer.get_children():
		if node is not CanvasItem:
			continue
		var node_rect: Rect2 = get_node_rect(node)
		if node_rect.intersects(_selection_rect.abs()):
			if node is PolyLine2D:
				_handle_poly_line_2d_selection(query, selection_receipt, node as PolyLine2D, _selection_rect)
				continue
			match query.type:
				SelectionQuery.Type.POINT:
					if not selection_receipt.selected_points.has(node):
						selection_receipt.selected_points[node] = []
				SelectionQuery.Type.NODE:
					if selection_receipt.selected_nodes.is_empty():
						selection_receipt.selected_nodes.append(node)
					else:
						selection_receipt.clear()
						break
				SelectionQuery.Type.NODES:
					selection_receipt.selected_nodes.append(node)
	return selection_receipt


## Converts [Rect2] to [PackedVector2Array]. The first point is at the 
## [member Rect2.position], the following points  are at the clockwize
## direction of the rectangle.
static func rect2_to_packed_vector2_array(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	])


func handle_receipt(receipt:SelectionReceipt, query: SelectionQuery = _query) -> void:
	match query.mode:
		SelectionQuery.Mode.ADD:
			add_to_selection(query, receipt)
		SelectionQuery.Mode.REPLACE:
			remove_from_selection(_selection_receipt)
			add_to_selection(query, receipt)
		SelectionQuery.Mode.SUBTRACT:
			remove_from_selection(receipt)
	selection_changed.emit(receipt)
	selection_rect.size = Vector2.ZERO


## Adds specified [param node] to "selection" group
func add_to_selection(query: SelectionQuery, receipt: SelectionReceipt) -> void:
	match query.type:
		SelectionQuery.Type.POINT:
			for node: Node in receipt.selected_points.keys():
				if node.has_method(&"select_points"):
					node.call(&"select_points", receipt.selected_points[node])
				elif node.has_method(&"add_to_selection"):
					node.call(&"add_to_selection")
				if not _selection_receipt.selected_points.has(node):
					_selection_receipt.selected_points[node] = PackedInt32Array()
				_selection_receipt.selected_points[node].append_array(receipt.selected_points[node])
		SelectionQuery.Type.NODE:
			var node: Node = receipt.selected_nodes[0]
			if node.has_method(&"add_to_selection"):
				node.call(&"add_to_selection")
			_selection_receipt.selected_nodes.append(node)
		SelectionQuery.Type.NODES:
			for node: Node in receipt.selected_nodes:
				if node.has_method(&"add_to_selection"):
					node.call(&"add_to_selection")
			_selection_receipt.selected_nodes.append_array(receipt.selected_nodes)


## Removes nodes and points from current selection.
func remove_from_selection(receipt: SelectionReceipt) -> void:
	if not receipt or receipt.is_empty():
		return
	for node: Node in receipt.selected_nodes:
		if node.has_method(&"remove_from_selection"):
			node.call(&"remove_from_selection")
		receipt.selected_nodes.erase(node)
	for node: Node in receipt.selected_points.keys():
		if node.has_method(&"deselect_points"):
			node.call(&"deselect_points", receipt.selected_points[node])
		elif node.has_method(&"remove_gizmos"):
			node.call(&"remove_gizmos")
		receipt.selected_points.erase(node)


## Returns bounding box of a node if it has such.
func get_node_rect(node: Node) -> Rect2:
	var rect: Rect2
	if node is PolyLine2D:
		var poly_line_2d: PolyLine2D = node
		rect = poly_line_2d.bounding_box
		rect.position += poly_line_2d.position
	elif node is LLineEdit:
		var l_line_edit: LLineEdit = node
		rect = l_line_edit.get_global_rect()
	return rect


## Clears the selection.
func clear_selection() -> void:
	_selection_receipt.clear()
	get_tree().call_group(&"selection", &"remove_from_selection")


## Receives a [SelectionQuery] to process further selection.
func request_selection(query: SelectionQuery) -> void:
	can_select = true
	_query = query


## Gets the [SelectionQuery.Mode].
func get_selection_mode() -> SelectionQuery.Mode:
	return _query.mode


## Sets the [SelectionQuery.Mode].
func set_selection_mode(mode: SelectionQuery.Mode) -> void:
	_query.mode = mode


## Returns the size of single click selection.
func get_singale_click_vector() -> Vector2:
	return Vector2(single_click_size, single_click_size)


## Resets query to use default parameters of [SelectionQuery].
func reset_query() -> void:
	_query = SelectionQuery.new()


func get_current_selection() -> SelectionReceipt:
	return _selection_receipt


## Determines if a [PolyLine2D] should be selected.
func _handle_poly_line_2d_selection(
	query: SelectionQuery,
	receipt: SelectionReceipt,
	poly_line_2d: PolyLine2D,
	_selection_rect: Rect2
) -> void:
	var poly_line_points: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in poly_line_2d.points:
		poly_line_points.append(point + poly_line_2d.position)
	if query.type == SelectionQuery.Type.POINT:
		for point: int in range(poly_line_points.size()):
			var point_inside_selection: bool = Geometry2D.is_point_in_polygon(
				poly_line_points[point],
				rect2_to_packed_vector2_array(_selection_rect)
			)
			if not receipt.selected_points.has(poly_line_2d):
				receipt.selected_points[poly_line_2d] = PackedInt32Array()
			if point_inside_selection:
				receipt.selected_points[poly_line_2d].append(point)
	else:
		var intersection: Array[PackedVector2Array] = Geometry2D.intersect_polyline_with_polygon(
			poly_line_points,
			rect2_to_packed_vector2_array(_selection_rect)
			)
		if not intersection.is_empty():
			receipt.selected_nodes.append(poly_line_2d)


func _get_interactive_selection(query: SelectionQuery = _query) -> void:
	var selection_receipt: SelectionReceipt = get_selection(query, selection_rect)
	handle_receipt(selection_receipt, query)
