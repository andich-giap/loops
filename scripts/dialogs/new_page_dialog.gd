class_name CreateNewPageDialog
extends ConfirmationDialog


signal page_created(page_data: PageData)
signal new_page_name_changed(name: String)
@onready var designation_line_edit: LineEdit = $VBoxContainer/Designation/DesignationLineEdit
@onready var name_line_edit: LineEdit = $VBoxContainer/Name/NameLineEdit
@onready var description_line_edit: LineEdit = $VBoxContainer/Description/DescriptionLineEdit
@onready var type_option_button: OptionButton = $VBoxContainer/Type/TypeOptionButton
@onready var new_page_name_line_edit: LineEdit = %NameLineEdit


func _ready() -> void:
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)
	for type: String in PageData.Type.keys():
		type = tr(type)
		type_option_button.add_item(type)
	new_page_name_line_edit.text_changed.connect(new_page_name_changed.emit)


func activate(last_page_in_tree: PageData) -> void:
	name_line_edit.theme_type_variation = ""
	if not last_page_in_tree:
		description_line_edit.text = ""
		description_line_edit.text = ""
		type_option_button.select(0)
		name_line_edit.text = "1"
		visible = true
		return
	var new_page_name: StringName = last_page_in_tree.name
	if last_page_in_tree.name.is_valid_int():
		new_page_name = str(int(last_page_in_tree.name) + 1)
	description_line_edit.text = last_page_in_tree.designation.to_string()
	description_line_edit.text = last_page_in_tree.description
	type_option_button.select(last_page_in_tree.type)
	name_line_edit.text = new_page_name
	visible = true


func _on_confirmed() -> void:
	visible = false
	var page_data: PageData = PageData.new()
	page_data.designation = DesignationsData.new() # TODO Add conversion from string to DesignationData or implement NewDesignationDialog
	page_data.name = name_line_edit.text
	page_data.description = description_line_edit.text
	
	var type: PageData.Type
	var type_names: Array[String] = []
	for type_name: String in PageData.Type:
		type_names.append(tr(type_name))
	if type_names.has(type_option_button.get_item_text(type_option_button.selected)):
		page_data.type = type_option_button.selected as PageData.Type
	page_created.emit(page_data)


func _on_canceled() -> void:
	visible = false
