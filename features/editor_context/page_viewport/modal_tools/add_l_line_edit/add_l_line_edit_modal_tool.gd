class_name AddLLineEditModalTool
extends ModalTool


enum State {
	STARTING,
	WAITING_FOR_POSITION,
	EXECUTING,
	FINISHING,
}
var l_line_edit: LLineEdit
var current_state: State = State.STARTING


func enter(__target_nodes: Array[Node], preview_layer: CanvasLayer) -> void:
	l_line_edit = LLineEdit.new()
	_preview_layer = preview_layer
	_preview_layer.add_child(l_line_edit)
	request_place_position.emit()
	current_state = State.WAITING_FOR_POSITION


func handle_input(event: InputEvent) -> void:
	if not current_state == State.WAITING_FOR_POSITION:
		return
	if event is InputEventMouseMotion:
		l_line_edit.position = _page_viewport.get_snapped_position().snapped_position
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.is_released() \
			and mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			l_line_edit.position = _page_viewport.get_snapped_position().snapped_position
			current_state = State.EXECUTING
			execute()


func execute() -> void:
	var add_l_line_edit_receipt: AddLLineEditReceipt = AddLLineEditReceipt.new(l_line_edit)
	current_state = State.FINISHING
	exit(add_l_line_edit_receipt)


func exit(receipt: ModalToolReceipt) -> void:
	_preview_layer.remove_child(l_line_edit)
	finished.emit(receipt)


func deactivate_modal_tool() -> void:
	if not current_state == State.FINISHING:
		l_line_edit.queue_free()
