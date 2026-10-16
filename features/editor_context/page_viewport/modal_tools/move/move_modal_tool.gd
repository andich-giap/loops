class_name MoveModalTool
extends ModalTool


enum State {
	STARTING,
	SELECTING,
	WAITING_FOR_BASE_POINT,
	PREVIEWING,
	EXECUTING,
	FINISHING,
}
var current_state: State = State.STARTING
var base_point: Vector2
var end_point: Vector2
var _selection_query: SelectionQuery = SelectionQuery.new(SelectionQuery.Type.NODES)


func enter(target_nodes: Array[Node], preview_layer: CanvasLayer) -> void:
	super(target_nodes, preview_layer)
	if target_nodes.is_empty():
		selection_requested.emit(_selection_query)
		selection_received.connect(_on_selection_received)
		current_state = State.SELECTING
		return
	current_state = State.WAITING_FOR_BASE_POINT


func handle_input(event: InputEvent) -> void:
	match current_state:
		State.WAITING_FOR_BASE_POINT:
			handle_input_waiting_for_base_point(event)
		State.PREVIEWING:
			handle_input_previewing(event)
		_:
			return


func handle_input_waiting_for_base_point(event: InputEvent) -> void:
	var snapped_position: Vector2
	if event is InputEventMouseMotion:
		snapped_position = _page_viewport.get_snapped_position().snapped_position
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if not mouse_button_event.button_index == MOUSE_BUTTON_LEFT \
			or not mouse_button_event.is_released():
			return
		snapped_position = _page_viewport.get_snapped_position().snapped_position
		var canvas_transform: Transform2D = _preview_layer.get_viewport().canvas_transform
		base_point = canvas_transform.affine_inverse() * snapped_position
		current_state = State.PREVIEWING


func handle_input_previewing(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var canvas_transform: Transform2D = _preview_layer.get_viewport().canvas_transform
		var snapped_position: Vector2 = _page_viewport.get_snapped_position().snapped_position
		var current_canvas_mouse: Vector2 = canvas_transform.affine_inverse() * snapped_position
		var canvas_delta: Vector2 = current_canvas_mouse - base_point
		_preview_layer.transform = Transform2D.IDENTITY.translated(canvas_delta)
	if event is InputEventMouseButton:
		var canvas_transform: Transform2D = _preview_layer.get_viewport().canvas_transform
		var snapped_position: Vector2 = _page_viewport.get_snapped_position().snapped_position
		var mouse_button_event: InputEventMouseButton = event
		if not mouse_button_event.button_index == MOUSE_BUTTON_LEFT \
			or not mouse_button_event.is_released():
			return
		current_state = State.EXECUTING
		var final_canvas_mouse: Vector2 = canvas_transform.affine_inverse() * snapped_position
		execute(final_canvas_mouse)


func execute(end_position: Vector2) -> void:
	end_point = end_position
	var move_receipt: MoveReceipt = MoveReceipt.new(
		_target_nodes,
		base_point - end_point
	)
	current_state = State.FINISHING
	exit(move_receipt)


func _on_selection_received(receipt: SelectionReceipt) -> void:
	if receipt.is_empty():
		selection_requested.emit(_selection_query)
		return
	_target_nodes = receipt.selected_nodes
	Utils.call_nodes(receipt.selected_nodes, &"remove_gizmos")
	_add_graphics_preview()
	current_state = State.WAITING_FOR_BASE_POINT
