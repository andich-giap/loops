@tool
class_name BoolPropertyEdit
extends PropertyEdit


@export var value: bool = false:
	set = set_value
var _initial_value: bool
var _default_value: bool
@onready var check_box: CheckBox = %CheckBox
var test_obj: Control

func _ready() -> void:
	super()
	hide_revert_button()
	revert_button.pressed.connect(_on_revert_button_pressed)
	
	check_box.toggled.connect(_on_check_box_toggled)
	
	test_obj = Control.new()
	for prop: Dictionary in test_obj.get_property_list():
		if prop[&"name"] == &"clip_contents":
			set_property(test_obj, prop, true)


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
	
	if is_multivalue:
		check_box.add_theme_icon_override(
			&"unchecked",
			check_box.get_theme_icon(&"multivalue", &"BoolPropertyEditCheckBox")
		)
		check_box.pressed.connect(_on_check_box_pressed, CONNECT_ONE_SHOT)


func set_value(_value: bool) -> void:
	if value == _value:
		return
	value = _value
	value_changed.emit()
	if is_instance_valid(check_box) and not check_box.button_pressed == value:
		check_box.set_pressed_no_signal(value)
	if is_instance_valid(revert_button):
		if not value == _default_value:
			show_revert_button()
		else:
			hide_revert_button()


func _on_revert_button_pressed() -> void:
	value = _default_value
	hide_revert_button()


func _on_check_box_pressed() -> void:
	check_box.remove_theme_icon_override(&"unchecked")


func _on_check_box_toggled(toggled_on: bool) -> void:
	if undo_redo and not _property.is_empty():
		var property_name: StringName = _property[&"name"]
		undo_redo.create_action("Set value for bool property " + property_name)
		undo_redo.add_do_property(self, &"value", toggled_on)
		undo_redo.add_undo_property(self, &"value", value)
		undo_redo.commit_action()
	else:
		value = toggled_on
