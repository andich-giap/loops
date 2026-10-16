@abstract
class_name ModalTool
extends RefCounted


signal started
signal finished(receipt: ModalToolReceipt)
@warning_ignore_start("unused_signal")
signal selection_requested(selection_query: SelectionQuery)
signal request_place_position
@warning_ignore_restore("unused_signal")
signal selection_received(receipt: SelectionReceipt)
var _target_nodes: Array[Node]
var _preview_layer: CanvasLayer
var _page_viewport: PageViewport


func _init(page_viewport: PageViewport = null) -> void:
	_page_viewport = page_viewport


func enter(target_nodes: Array[Node], preview_layer: CanvasLayer) -> void:
	_target_nodes = target_nodes
	_preview_layer = preview_layer
	_add_graphics_preview()
	started.emit()


func exit(receipt: ModalToolReceipt) -> void:
	for child: Node in _preview_layer.get_children():
		if child is CanvasModulate:
			continue
		child.queue_free()
	finished.emit(receipt)


func receive_selection(receipt: SelectionReceipt) -> void:
	_target_nodes = receipt.selected_nodes
	selection_received.emit(receipt)


@abstract func handle_input(event: InputEvent) -> void


func _add_graphics_preview() -> void:
	if not _preview_layer or _target_nodes.is_empty():
		return
	for node: Node in _target_nodes:
		var preview_node: Node = node.duplicate()
		_preview_layer.add_child(preview_node)


func deactivate_modal_tool() -> void:
	pass
