class_name DuplicateReceipt
extends ModalToolReceipt


signal nodes_added(duplicate_nodes: Array[Node])
var move_vector: Vector2


func _init(_target_nodes: Array[Node], _move_vector: Vector2) -> void:
	target_nodes = _target_nodes
	move_vector = _move_vector


func apply_changes() -> void:
	var duplicate_nodes: Array[Node]
	for node: Node in target_nodes:
		var duplicate_node: Node = node.duplicate()
		duplicate_node.set(&"position", duplicate_node.get(&"position") - move_vector)
		if duplicate_node.has_method(&"update_bounding_box"):
			duplicate_node.call(&"update_bounding_box")
		duplicate_nodes.append(duplicate_node)
	nodes_added.emit(duplicate_nodes)
