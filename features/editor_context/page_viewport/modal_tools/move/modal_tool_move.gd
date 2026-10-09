class_name ModalToolMove
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


func enter(target_nodes: Array[Node], preview_layer: CanvasLayer) -> void:
	super(target_nodes, preview_layer)
	if target_nodes.is_empty():
		selection_requested.emit(SelectionQuery.new(SelectionQuery.Type.NODES))
		current_state = State.SELECTING
		return
	current_state = State.WAITING_FOR_BASE_POINT


func handle_input(event: InputEvent) -> void:
	match current_state:
		State.SELECTING:
			await handle_input_selecting(event)
		State.WAITING_FOR_BASE_POINT:
			handle_input_waiting_for_base_point(event)
		State.PREVIEWING:
			handle_input_previewing(event)
		_:
			return


func handle_input_selecting(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return
	var mouse_button_event: InputEventMouseButton = event
	if not mouse_button_event.button_index == MOUSE_BUTTON_LEFT \
		or not mouse_button_event.is_released():
		return
	await _preview_layer.get_tree().process_frame
	var selected_nodes: Array[Node] = _preview_layer.get_tree().get_nodes_in_group(&"selection")
	if selected_nodes.is_empty():
		return
	_target_nodes = selected_nodes
	selection_received.emit()
	current_state = State.WAITING_FOR_BASE_POINT


func handle_input_waiting_for_base_point(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pass ## TODO: Query for snapping preview?
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if not mouse_button_event.button_index == MOUSE_BUTTON_LEFT \
			or not mouse_button_event.is_released():
			return
		base_point = mouse_button_event.position
		current_state = State.PREVIEWING


func handle_input_previewing(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_motion_event: InputEventMouseMotion = event
		_preview_layer.offset += mouse_motion_event.relative
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if not mouse_button_event.button_index == MOUSE_BUTTON_LEFT \
			or not mouse_button_event.is_released():
			return
		current_state = State.EXECUTING
		execute_move(base_point, mouse_button_event.position)


func execute_move(from_position: Vector2, to_position: Vector2) -> void:
	var move_receipt: MoveReceipt = MoveReceipt.new(
		_target_nodes,
		from_position - to_position
	)
	current_state = State.FINISHING
	exit(move_receipt)
