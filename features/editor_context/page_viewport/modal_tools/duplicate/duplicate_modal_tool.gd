class_name DuplicateModalTool
extends MoveModalTool


func execute(end_position: Vector2) -> void:
	end_point = end_position
	var duplicate_receipt: DuplicateReceipt = DuplicateReceipt.new(
		_target_nodes,
		base_point - end_point
	)
	current_state = State.FINISHING
	exit(duplicate_receipt)
