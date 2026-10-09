class_name ModalToolsManager
extends Node


signal selection_requested(selection_query: SelectionQuery)
signal selection_received
signal modal_tool_finished_executing(receipt: ModalToolReceipt)
var active_tool: ModalTool
var preview_layer: CanvasLayer


func activate_modal_tool(modal_tool: GDScript, target_nodes: Array[Node]) -> void:
	active_tool = modal_tool.new()
	active_tool.enter(target_nodes, preview_layer)
	active_tool.finished.connect(_on_active_tool_finished)
	active_tool.selection_requested.connect(selection_requested.emit)
	active_tool.selection_received.connect(selection_received.emit)


func handle_input(event: InputEvent) -> void:
	if not active_tool:
		return
	active_tool.handle_input(event)


func _on_active_tool_finished(receipt: ModalToolReceipt) -> void:
	modal_tool_finished_executing.emit(receipt)


func receive_selection(target_nodes: Array[Node], ...args: Array) -> void:
	active_tool.receive_selection(target_nodes, args)
