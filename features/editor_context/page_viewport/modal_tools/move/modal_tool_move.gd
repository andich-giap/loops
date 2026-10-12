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
var end_point: Vector2


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
			handle_input_selecting(event)
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
		var canvas_transform: Transform2D = _preview_layer.get_viewport().canvas_transform
		base_point = canvas_transform.affine_inverse() * mouse_button_event.position
		current_state = State.PREVIEWING


func handle_input_previewing(event: InputEvent) -> void:
	var canvas_transform: Transform2D = _preview_layer.get_viewport().canvas_transform
	if event is InputEventMouseMotion:
		var mouse_motion_event: InputEventMouseMotion = event
		var current_canvas_mouse: Vector2 = canvas_transform.affine_inverse() * mouse_motion_event.position
		var canvas_delta: Vector2 = current_canvas_mouse - base_point
		_preview_layer.transform = Transform2D.IDENTITY.translated(canvas_delta)
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if not mouse_button_event.button_index == MOUSE_BUTTON_LEFT \
			or not mouse_button_event.is_released():
			return
		current_state = State.EXECUTING
		var final_canvas_mouse: Vector2 = canvas_transform.affine_inverse() * mouse_button_event.position
		execute_move(final_canvas_mouse)


func execute_move(end_position: Vector2) -> void:
	end_point = end_position
	var move_receipt: MoveReceipt = MoveReceipt.new(
		_target_nodes,
		base_point - end_point
	)
	current_state = State.FINISHING
	exit(move_receipt)
