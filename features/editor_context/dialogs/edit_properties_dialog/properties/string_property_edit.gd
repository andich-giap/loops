@tool
class_name StringPropertyEdit
extends PropertyEdit


@export var value: String = "":
	set = set_value
var _initial_value: String
var _default_value: String
@onready var line_edit: LineEdit = %LineEdit


func _ready() -> void:
	super()
	hide_revert_button()
	revert_button.pressed.connect(_on_revert_button_pressed)
	
	line_edit.text_changed.connect(set_value)


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


func set_value(_value: String) -> void:
	if value == _value:
		return
	if undo_redo and not _property.is_empty():
		var property_name: StringName = _property[&"name"]
		undo_redo.create_action("Set value for String property " + property_name)
		undo_redo.add_do_property(self, &"value", _value)
		undo_redo.add_undo_property(self, &"value", value)
		undo_redo.commit_action()
	else:
		value = _value
	value_changed.emit()
	if is_instance_valid(line_edit) and not line_edit.text == value:
		if not line_edit.text_changed.is_connected(set_value):
			line_edit.text = value
		else:
			line_edit.text_changed.disconnect(set_value)
			line_edit.text = value
			line_edit.text_changed.connect(set_value)
	if is_instance_valid(revert_button):
		if not value == _default_value:
			show_revert_button()
		else:
			hide_revert_button()


func _on_revert_button_pressed() -> void:
	value = _default_value
	hide_revert_button()
