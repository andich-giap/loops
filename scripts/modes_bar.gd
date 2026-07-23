extends HBoxContainer


func _on_ortho_toggled(toggled_on: bool) -> void:
	Grid.is_orthogonal = toggled_on
