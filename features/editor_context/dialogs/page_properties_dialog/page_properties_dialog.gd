class_name PagePropertiesDialog
extends ConfirmationDialog


@onready var designation_line_edit: LineEdit = %DesignationLineEdit
@onready var designation_options_button: Button = %DesignationOptionsButton
@onready var page_type_menu_button: MenuButton = %PageTypeMenuButton
@onready var description_line_edit: LineEdit = %DescriptionLineEdit
@onready var properties_container: VBoxContainer = %PropertiesContainer
@onready var header: HSplitContainer = %Header
var _changed_properties: Dictionary[StringName, Variant]
var initial_values: Dictionary[StringName, Variant]
var apply_callable: Callable


func _ready() -> void:
	for type: StringName in PageData.Type.keys():
		page_type_menu_button.get_popup().add_item(type)
	page_type_menu_button.text = PageData.Type.keys()[0]
	canceled.connect(_on_canceled)
	
	designation_line_edit.text_changed.connect(_on_designation_line_edit_text_changed)
	page_type_menu_button.get_popup().index_pressed.connect(_on_type_changed)
	description_line_edit.text_changed.connect(_on_description_line_edit_text_changed)


func activate(page_datas: Array[PageData]) -> void:
	show()
	designation_line_edit.text = page_datas[0].get_full_name()
	page_type_menu_button.text = PageData.Type.keys()[page_datas[0].type]
	description_line_edit.text = page_datas[0].description
	for page_data: PageData in page_datas:
		if page_data == page_datas[0]:
			continue
		if not designation_line_edit.text == page_data.get_full_name():
			designation_line_edit.text = "..."
		if not page_type_menu_button.text == PageData.Type.keys()[page_data.type]:
			page_type_menu_button.text = "..."
		if not description_line_edit.text == page_data.description:
			description_line_edit.text = "..."
	initial_values[&"designation"] = designation_line_edit.text
	initial_values[&"type"] = PageData.Type.values()[page_type_menu_button.text.to_int()]
	initial_values[&"description"] = description_line_edit.text
	_changed_properties.clear()
	apply_callable  = apply_changes.bind(page_datas)
	confirmed.connect(apply_callable, CONNECT_ONE_SHOT)


func _on_canceled() -> void:
	hide()
	confirmed.disconnect(apply_callable)


func populate_properties(_page_datas: Array[PageData]) -> void:
	pass


func apply_changes(page_datas: Array[PageData]) -> void:
	for page: PageData in page_datas:
		for property: StringName in _changed_properties.keys():
			if property == &"designation":
				if initial_values[&"designation"] == "...":
					continue
				var designation_string: String = _changed_properties[property]
				var page_name: String = designation_string.split("_")[-1]
				var designation: DesignationsData = DesignationsData.new(
					designation_string.replace(page_name, "")
				)
				page.name = page_name
				page.designation = designation
			page.set(property, _changed_properties[property])


func _on_designation_line_edit_text_changed(new_text: String) -> void:
	if not new_text == initial_values[&"designation"]:
		_changed_properties[&"designation"] = new_text


func _on_type_changed(type: int) -> void:
	page_type_menu_button.text = PageData.Type.keys()[type]
	_changed_properties[&"type"] = PageData.Type.values()[type]


func _on_description_line_edit_text_changed(new_text: String) -> void:
	if not new_text == initial_values[&"description"]:
		_changed_properties[&"description"] = new_text
