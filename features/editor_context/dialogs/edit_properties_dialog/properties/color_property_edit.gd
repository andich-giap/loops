class_name ColorPropertyEdit
extends PropertyEdit


@export var value: Color = Color.BLACK:
	set = set_value
var _initial_value: Color
var _default_value: Color
@onready var color_picker_button: ColorPickerButton = %ColorPickerButton


func _ready() -> void:
	super()
	color_picker_button.popup_closed.connect(_on_controller_value_changed)


func set_property(object: Object, property: Dictionary, is_multivalue: bool = false) -> void:
	super(object, property, is_multivalue)
	var property_name: StringName = property[&"name"]
	
	value = object.get(property_name)
	_initial_value = value
	unmark_changed()
	
	var default_value: Variant = _get_property_default_value(object, property_name)
	if not typeof(default_value) == TYPE_NIL:
		_default_value = default_value
	
	if is_multivalue:
		_mark_multivalue()


func set_theme_property(
	control: Control,
	property_data_type: Theme.DataType,
	property_name: StringName,
	is_multivalue: bool = false
) -> void:
	super(control, property_data_type, property_name, is_multivalue)
	
	var theme_type: StringName = control.theme_type_variation
	
	if not theme_type:
		theme_type = control.get_class()
	
	value = control.get_theme_color(property_name, theme_type)
	_initial_value = value
	unmark_changed()
	
	var property_theme: Theme = _get_theme(control)
	if property_theme.has_color(property_name, theme_type):
		_default_value = property_theme.get_color(property_name, theme_type)
	
	if is_multivalue:
		_mark_multivalue()


func set_value(_value: Color) -> void:
	if is_instance_valid(color_picker_button) and not _is_multivalue \
		and not color_picker_button.color == _value:
		color_picker_button.set_block_signals(true)
		color_picker_button.color = _value
		color_picker_button.set_block_signals(false)
	
	if is_instance_valid(revert_button):
		if _is_multivalue or not _value == _default_value:
			show_revert_button()
		else:
			hide_revert_button()
	
	if value == _value:
		return
	value = _value
	if value == _initial_value:
		unmark_changed()
	else:
		mark_changed()


func get_edited_property_value() -> Variant:
	return value


func apply_value_to_initial() -> void:
	super()
	_initial_value = value


func revert_to_default() -> void:
	_commit_value(_default_value, "Color")
	super()


func revert_to_initial() -> void:
	_commit_value(_initial_value, "Color")
	super()


func _on_controller_value_changed() -> void:
	var _value: Color = color_picker_button.color
	if not value == _value:
		_commit_value(_value, &"Color")


func _mark_multivalue() -> void:
	_unmark_multivalue()
	set_block_signals(true)
	color_picker_button.color = Color.WHITE_SMOKE
	set_block_signals(false)
	var multivalue_label: Label = Label.new()
	multivalue_label.name = &"MultivalueLabel"
	multivalue_label.text = "<...>"
	multivalue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	multivalue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	multivalue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	multivalue_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_picker_button.add_child(multivalue_label)


func _unmark_multivalue() -> void:
	var existing: Node = color_picker_button.get_node_or_null(^"MultivalueLabel")
	if existing:
		existing.free()
