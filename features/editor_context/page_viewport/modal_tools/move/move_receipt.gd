class_name MoveReceipt
extends ModalToolReceipt


var move_vector: Vector2


func _init(_target_nodes: Array[Node], _move_vector: Vector2) -> void:
	target_nodes = _target_nodes
	move_vector = _move_vector


func apply_changes() -> void:
	for node: Node in target_nodes:
		node.set(&"position", node.get(&"position") - move_vector)
		if node.has_method(&"update_bounding_box"):
			node.call(&"update_bounding_box")
		if node.has_method(&"add_gizmos"):
			node.call(&"add_gizmos")
