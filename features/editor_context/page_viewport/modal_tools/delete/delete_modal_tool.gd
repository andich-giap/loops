class_name DeleteModalTool
extends ModalTool


enum State {
	STARTING,
	SELECTING,
	EXECUTING,
	FINISHING,
}
var current_state: State = State.STARTING
var _selection_query: SelectionQuery = SelectionQuery.new(SelectionQuery.Type.NODES)


func enter(target_nodes: Array[Node], preview_layer: CanvasLayer) -> void:
	super(target_nodes, preview_layer)
	if target_nodes.is_empty():
		selection_requested.emit(_selection_query)
		selection_received.connect(_on_selection_received)
		current_state = State.SELECTING
		return
	current_state = State.EXECUTING
	execute()


func handle_input(_event: InputEvent) -> void:
	pass


func execute() -> void:
	var move_receipt: DeleteReceipt = DeleteReceipt.new(_target_nodes)
	current_state = State.FINISHING
	exit(move_receipt)


func _on_selection_received(receipt: SelectionReceipt) -> void:
	if receipt.is_empty():
		selection_requested.emit(_selection_query)
		return
	_target_nodes = receipt.selected_nodes
	Utils.call_nodes(receipt.selected_nodes, &"remove_gizmos")
	current_state = State.EXECUTING
	execute()
