class_name ColorPropertyEdit
extends PropertyEdit


@export var value: Color = Color.BLACK:
	set = set_value
var _initial_value: Color
var _default_value: Color
@onready var color_picker_button: ColorPickerButton = %ColorPickerButton


func _ready() -> void:
	super()
	
	hide_revert_button()
	revert_button.pressed.connect(_on_revert_button_pressed)
	color_picker_button.color_changed.connect(_on_contorller_value_changed)


func set_property(object: Object, property: Dictionary, is_multivalue: bool = false) -> void:
	super(object, property, is_multivalue)
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
	
	var property_theme: Theme = _get_theme(control)
	if property_theme.has_color(property_name, theme_type):
		_default_value = property_theme.get_color(property_name, theme_type)


func set_value(_value: Color) -> void:
	if is_instance_valid(color_picker_button) and not color_picker_button.color == _value:
		if not color_picker_button.color_changed.is_connected(set_value):
			color_picker_button.color = _value
		else:
			color_picker_button.color_changed.disconnect(set_value)
			color_picker_button.color = _value
			color_picker_button.color_changed.connect(set_value)
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


func _on_contorller_value_changed(_value: Color) -> void:
	if undo_redo:
		var property_name: StringName = label.text.to_lower()
		undo_redo.create_action("Set value for Color property " + property_name)
		undo_redo.add_do_property(self, &"value", _value)
		undo_redo.add_undo_property(self, &"value", _value)
		undo_redo.commit_action()
	else:
		value = _value
