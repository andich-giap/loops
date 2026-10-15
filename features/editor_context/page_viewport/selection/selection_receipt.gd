class_name SelectionReceipt
extends RefCounted
## The receipt that forms in response to the [SelectionQuery].


var selected_nodes: Array[Node] ## Nodes that were selected after the [SelectionQuery].
var selected_points: Dictionary[Node, PackedInt32Array] ## Points that were selected after the [SelectionQuery].


func clear() -> void:
	selected_nodes.clear()
	selected_points.clear()


func is_empty() -> bool:
	if selected_nodes.is_empty() and selected_points.is_empty():
		return true
	return false
