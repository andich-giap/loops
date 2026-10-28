@tool
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
	
	color_picker_button.color_changed.connect(set_value)


func set_property(object: Object, property: Dictionary, is_multivalue: bool = false) -> void:
	super(object, property, is_multivalue)
	var property_name: StringName = _property[&"name"]
	
	value = object.get(property_name)
	_initial_value = value
	if object.get_script():
		var script: Script = object.get_script()
		_default_value = script.get_property_default_value(property_name)
	else:
		var property_class: StringName = object.get_class()
		_default_value = ClassDB.class_get_property_default_value(property_class, property_name)
	
	if value == _default_value:
		hide_revert_button()


func set_value(_value: Color) -> void:
	if value == _value:
		return
	if undo_redo and not _property.is_empty():
		var property_name: StringName = _property[&"name"]
		undo_redo.create_action("Set value for Color property " + property_name)
		undo_redo.add_do_property(self, &"value", _value)
		undo_redo.add_undo_property(self, &"value", value)
		undo_redo.commit_action()
	else:
		value = _value
	value_changed.emit()
	if is_instance_valid(color_picker_button) and not color_picker_button.color == value:
		if not color_picker_button.color_changed.is_connected(set_value):
			color_picker_button.color = value
		else:
			color_picker_button.color_changed.disconnect(set_value)
			color_picker_button.color = value
			color_picker_button.color_changed.connect(set_value)
	if is_instance_valid(revert_button):
		if not value == _default_value:
			show_revert_button()
		else:
			hide_revert_button()


func _on_revert_button_pressed() -> void:
	value = _default_value
	hide_revert_button()
