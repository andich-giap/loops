class_name IntPropertyEdit
extends PropertyEdit


@export var value: int = 0:
	set = set_value
var _initial_value: int
var _default_value: int
@onready var spin_box: SpinBox = %SpinBox


func _ready() -> void:
	super()
	hide_revert_button()
	revert_button.pressed.connect(_on_revert_button_pressed)
	
	var line_edit: LineEdit = spin_box.get_line_edit()
	line_edit.theme_type_variation = &"PropertyLineEdit"
	
	spin_box.value_changed.connect(set_value)
	spin_box.gui_input.connect(_on_spin_box_gui_input)


func set_property(object: Object, property: Dictionary, is_multivalue: bool = false) -> void:
	super(object, property, is_multivalue)
	var hint_string: String = property[&"hint_string"]
	var property_name: StringName = property[&"name"]
	
	value = object.get(property_name)
	_initial_value = value
	if object.get_script():
		var script: Script = object.get_script()
		_default_value = script.get_property_default_value(property_name)
	else:
		var property_class: StringName = object.get_class()
		var default_value: Variant = ClassDB.class_get_property_default_value(property_class, property_name)
		if not typeof(default_value) == TYPE_NIL:
			_default_value = default_value
	
	if value == _default_value:
		hide_revert_button()
	
	if hint_string.contains("suffix:"):
		var suffix: String = hint_string.split("suffix:")[1]
		spin_box.suffix = suffix.strip_edges()


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
	
	var property_theme: Theme = _get_theme(control)
	if property_theme.has_color(property_name, theme_type):
		if property_data_type == Theme.DataType.DATA_TYPE_CONSTANT:
			_default_value = property_theme.get_constant(property_name, theme_type)
		elif property_data_type == Theme.DataType.DATA_TYPE_FONT_SIZE:
			_default_value = property_theme.get_font_size(property_name, theme_type)


func set_value(_value: int) -> void:
	if is_instance_valid(spin_box) and not spin_box.value == _value:
		spin_box.set_value_no_signal(_value)
	if is_instance_valid(revert_button):
		if not _value == _default_value:
			show_revert_button()
		else:
			hide_revert_button()
	if value == _value:
		return
	value = _value
	value_changed.emit(value)
	if value == _initial_value:
		value_reverted_to_initial.emit()


func get_edited_property_value() -> Variant:
	return value


func _on_revert_button_pressed() -> void:
	value = _default_value
	hide_revert_button()
	value_reverted_to_default.emit()


func _on_spin_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if not mouse_button_event.is_command_or_control_pressed():
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spin_box.value = spin_box.value + spin_box.step
		elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spin_box.value = spin_box.value - spin_box.step



func _on_contorller_value_changed(_value: int) -> void:
	if undo_redo:
		var property_name: StringName = label.text.to_lower()
		undo_redo.create_action("Set value for int property " + property_name)
		undo_redo.add_do_property(self, &"value", _value)
		undo_redo.add_undo_property(self, &"value", value)
		undo_redo.commit_action()
	else:
		value = _value
