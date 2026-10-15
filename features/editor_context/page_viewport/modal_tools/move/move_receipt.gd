class_name MoveReceipt
extends ModalToolReceipt


var move_vector: Vector2


func _init(_target_nodes: Array[Node], _move_vector: Vector2) -> void:
	target_nodes = _target_nodes
	move_vector = _move_vector


func apply_changes(_page_viewport: PageViewport) -> void:
	for node: Node in target_nodes:
		Utils.call_node(node, &"set", &"set", [&"position", node.get(&"position") - move_vector])
		Utils.call_node(node, &"update_bounding_box")
		Utils.call_node(node, &"add_gizmos")
