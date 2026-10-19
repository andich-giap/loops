class_name AddLLineEditReceipt
extends ModalToolReceipt


var l_line_edit: LLineEdit


func _init(_l_line_edit: LLineEdit) -> void:
	l_line_edit = _l_line_edit


func apply_changes(page_viewport: PageViewport) -> void:
	page_viewport.add_graphics(l_line_edit)
	l_line_edit.changed.emit()
	l_line_edit.edit_text()
