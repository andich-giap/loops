class_name ModalToolsManager
extends Node


signal selection_requested(selection_query: SelectionQuery)
signal selection_received
signal modal_tool_finished_executing(receipt: ModalToolReceipt)
signal execution_cancelled
var active_tool: ModalTool
var preview_layer: CanvasLayer


func activate_modal_tool(modal_tool: GDScript, target_nodes: Array[Node]) -> void:
	active_tool = modal_tool.new()
	active_tool.finished.connect(_on_active_tool_finished)
	active_tool.selection_requested.connect(selection_requested.emit)
	active_tool.selection_received.connect(selection_received.emit)
	active_tool.enter(target_nodes, preview_layer)


func deactivate_modal_tool() -> void:
	active_tool = null


func handle_input(event: InputEvent) -> void:
	if not active_tool:
		return
	if event.is_action(&"ui_cancel"):
		deactivate_modal_tool()
		execution_cancelled.emit()
		return
	active_tool.handle_input(event)


func _on_active_tool_finished(receipt: ModalToolReceipt) -> void:
	modal_tool_finished_executing.emit(receipt)


func receive_selection(receipt: SelectionReceipt) -> void:
	active_tool.receive_selection(receipt)
