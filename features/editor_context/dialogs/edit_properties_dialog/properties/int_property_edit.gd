class_name IntPropertyEdit
extends PropertyEdit


@export var value: int = 0:
	set = set_value
var _initial_value: int
var _default_value: int
@onready var spin_box: SpinBox = %SpinBox


func _ready() -> void:
	super()
	var line_edit: LineEdit = spin_box.get_line_edit()
	line_edit.theme_type_variation = &"PropertyLineEdit"
	
	spin_box.value_changed.connect(_on_controller_value_changed)
	spin_box.gui_input.connect(_on_spin_box_gui_input)


func set_property(object: Object, property: Dictionary, is_multivalue: bool = false) -> void:
	super(object, property, is_multivalue)
	var hint_string: String = property[&"hint_string"]
	var property_name: StringName = property[&"name"]
	
	value = object.get(property_name)
	_initial_value = value
	unmark_changed()
	
	var default_value: Variant = _get_property_default_value(object, property_name)
	if not typeof(default_value) == TYPE_NIL:
		_default_value = default_value
	
	if hint_string.contains("suffix:"):
		var suffix: String = hint_string.split("suffix:")[1]
		spin_box.suffix = suffix.strip_edges()
	
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
	
	if property_data_type == Theme.DataType.DATA_TYPE_CONSTANT:
		value = control.get_theme_constant(property_name, theme_type)
	elif property_data_type == Theme.DataType.DATA_TYPE_FONT_SIZE:
		value = control.get_theme_font_size(property_name, theme_type)
	else:
		push_warning(" ".join([
			"Trying to assign property",
			property_name,
			"with Theme.DataType",
			str(property_data_type),
			"to a IntPropertyEdit"
		]))
		return
	_initial_value = value
	unmark_changed()
	
	var property_theme: Theme = _get_theme(control)
	if property_data_type == Theme.DataType.DATA_TYPE_CONSTANT \
		and property_theme.has_constant(property_name, theme_type):
			_default_value = property_theme.get_constant(property_name, theme_type)
	elif property_data_type == Theme.DataType.DATA_TYPE_FONT_SIZE \
		and property_theme.has_font_size(property_name, theme_type):
			_default_value = property_theme.get_font_size(property_name, theme_type)
	
	if is_multivalue:
		_mark_multivalue()


func set_value(_value: int) -> void:
	if is_instance_valid(spin_box) and not _is_multivalue and not spin_box.value == _value:
		spin_box.set_value_no_signal(_value)
	
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
	_commit_value(_default_value, "int")
	super()


func revert_to_initial() -> void:
	_commit_value(_initial_value, "int")
	super()


func _on_spin_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if not mouse_button_event.is_command_or_control_pressed():
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_on_controller_value_changed(int(spin_box.value + spin_box.step))
		elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_on_controller_value_changed(int(spin_box.value + spin_box.step))



func _on_controller_value_changed(_value: int) -> void:
	_commit_value(_value, &"int")


func _mark_multivalue() -> void:
	_unmark_multivalue()
	var line: LineEdit = spin_box.get_line_edit()
	line.set_block_signals(true)
	line.text = ""
	line.set_block_signals(false)
	line.placeholder_text = "<...>"


func _unmark_multivalue() -> void:
	spin_box.get_line_edit().placeholder_text = ""
