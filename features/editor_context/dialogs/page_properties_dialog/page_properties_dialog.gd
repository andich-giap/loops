class_name PagePropertiesDialog
extends ConfirmationDialog


@onready var designation_line_edit: LineEdit = %DesignationLineEdit
@onready var designation_options_button: Button = %DesignationOptionsButton
@onready var page_type_menu_button: MenuButton = %PageTypeMenuButton
@onready var description_line_edit: LineEdit = %DescriptionLineEdit
@onready var properties_container: VBoxContainer = %PropertiesContainer
@onready var header: HSplitContainer = %Header
var _changed_properties: Dictionary[StringName, Variant]


func _ready() -> void:
	canceled.connect(_on_canceled)
	#designation_line_edit.text_changed.connect()


func activate(page_datas: Array[PageData]) -> void:
	show()


func _on_canceled() -> void:
	hide()


func populate_properties(page_datas: Array[PageData]) -> void:
	pass


func apply_changes() -> void:
	pass
