@icon("res://addons/at-icons/node/wrench.svg")
class_name ModalToolsManager
extends Node


signal selection_requested(selection_query: SelectionQuery)
signal selection_received
signal modal_tool_finished_executing(receipt: ModalToolReceipt)
signal execution_cancelled
var active_tool: ModalTool
var preview_layer: CanvasLayer


func activate_modal_tool(modal_tool: GDScript, target_nodes: Array[Node], page_viewport: PageViewport) -> void:
	active_tool = modal_tool.new(page_viewport)
	active_tool.finished.connect(_on_active_tool_finished)
	active_tool.selection_requested.connect(selection_requested.emit)
	active_tool.selection_received.connect(selection_received.emit)
	active_tool.enter(target_nodes, preview_layer)


func deactivate_modal_tool() -> void:
	if not active_tool:
		return
	active_tool.deactivate_modal_tool()
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
	active_tool = null


func receive_selection(receipt: SelectionReceipt) -> void:
	if not active_tool:
		return
	active_tool.receive_selection(receipt)
