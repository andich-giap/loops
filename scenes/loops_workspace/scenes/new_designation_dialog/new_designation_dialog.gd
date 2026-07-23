@tool
class_name NewDesignationDialog
extends ConfirmationDialog


@onready var option_button: OptionButton = $VBoxContainer/OptionButton
@onready var name_line_edit: LineEdit = $VBoxContainer/NameLineEdit
@onready var description_text_edit: TextEdit = $VBoxContainer/DescriptionTextEdit
@onready var ok_button: Button = get_ok_button()


func _ready() -> void:
	option_button.clear()
	for type: Designation.Type in Designation.Type.values():
		option_button.add_item(Designation.designation_signs[type])
	ok_button.disabled = true


func _on_name_line_edit_text_changed(new_text: String) -> void:
	if not new_text == "":
		ok_button.disabled = false
	else:
		ok_button.disabled = true


func _on_canceled() -> void:
	queue_free()
