class_name DeleteReceipt
extends ModalToolReceipt


func _init(_target_nodes: Array[Node]) -> void:
	target_nodes = _target_nodes


func apply_changes(_page_viewport: PageViewport) -> void:
	Utils.call_nodes(target_nodes, &"delete")
