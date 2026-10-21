@icon("res://addons/at-icons/node/magnet.svg")
class_name SnapEngine
extends Node


signal snap_changed(receipt: SnapReceipt)
@export var viewport: Viewport ## Needed for transform considerations
var snap_constraints: Array[SnapConstraint] = []
var _excluded_nodes: Array[Node]


func _ready() -> void:
	if not viewport:
		viewport = get_viewport()


func resolve_snap(context_nodes: Array[Node], mouse_position: Vector2 = _get_mouse_position()) -> SnapReceipt:
	for node: Node in context_nodes.duplicate():
		if _excluded_nodes.has(node):
			context_nodes.erase(node)
		if node is Gizmo:
			context_nodes.erase(node)
	
	var canvas_transform: Transform2D = viewport.canvas_transform
	var zoom_factor: float = canvas_transform.x.length()
	var receipt: SnapReceipt
	var results: Dictionary[SnapConstraint, SnapReceipt]
	for constraint: SnapConstraint in snap_constraints:
		var result: SnapReceipt = constraint.get_snap(
			mouse_position,
			context_nodes,
			zoom_factor
		)
		results[constraint] = result
	receipt = _process_results(results)
	receipt.snapped_position_canvas_space = receipt.snapped_position
	receipt.snapped_position = canvas_transform * receipt.snapped_position
	snap_changed.emit(receipt)
	return receipt


func _process_results(results: Dictionary[SnapConstraint, SnapReceipt]) -> SnapReceipt:
	var receipts: Array[SnapReceipt] = results.values()
	var valid_receipts: Array[SnapReceipt]
	
	for receipt: SnapReceipt in receipts:
		if receipt.snap_successful:
			valid_receipts.append(receipt)
	
	if receipts.is_empty() or valid_receipts.is_empty():
		var mouse_position: Vector2 = _get_mouse_position()
		return SnapReceipt.new(
			mouse_position,
			SnapConstraint.Type.NONE,
			mouse_position,
			false
		)
	
	valid_receipts.sort_custom(
		func(a: SnapReceipt, b: SnapReceipt) -> bool:
			var constraint_a: SnapConstraint = results.find_key(a)
			var constraint_b: SnapConstraint = results.find_key(b)
			
			if not constraint_a.priority == constraint_b.priority:
				return constraint_a.priority > constraint_b.priority
			
			var distance_a: float = a.snapped_position.distance_to(a.mouse_position)
			var distance_b: float = b.snapped_position.distance_to(b.mouse_position)
			return distance_a < distance_b
	)
	return valid_receipts[0]


func _get_mouse_position() -> Vector2:
	var canvas_transform: Transform2D = viewport.canvas_transform
	return canvas_transform.affine_inverse() * viewport.get_mouse_position()


func exclude_from_snapping(nodes: Array[Node]) -> void:
	_excluded_nodes.append_array(nodes)


func clear_excluded_nodes() -> void:
	_excluded_nodes.clear()
