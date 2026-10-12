class_name DuplicateReceipt
extends ModalToolReceipt


var move_vector: Vector2


func _init(_target_nodes: Array[Node], _move_vector: Vector2) -> void:
	target_nodes = _target_nodes
	move_vector = _move_vector


func apply_changes() -> void:
	for node: Node in target_nodes:
		var parent: Node = node.get_parent()
		node = node.duplicate()
		parent.add_child(node)
		node.set(&"position", node.get(&"position") - move_vector)
		if node.has_method(&"update_bounding_box"):
			node.call(&"update_bounding_box")
