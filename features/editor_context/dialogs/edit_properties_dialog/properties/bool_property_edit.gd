class_name BoolPropertyEdit
extends PropertyEdit


@export var value: bool = false:
	set = set_value
var _initial_value: bool
var _default_value: bool
@onready var check_box: CheckBox = %CheckBox


func _ready() -> void:
	super()
	check_box.toggled.connect(_on_check_box_toggled)


func set_property(object: Object, property: Dictionary, is_multivalue: bool = false) -> void:
	super(object, property, is_multivalue)
	var property_name: StringName = property[&"name"]
	
	value = object.get(property_name)
	_initial_value = value
	unmark_changed()
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
	
	if is_multivalue:
		check_box.add_theme_icon_override(
			&"unchecked",
			check_box.get_theme_icon(&"multivalue", &"BoolPropertyEditCheckBox")
		)
		check_box.pressed.connect(_on_check_box_pressed, CONNECT_ONE_SHOT)


func set_value(_value: bool) -> void:
	if is_instance_valid(check_box) and not check_box.button_pressed == _value:
		check_box.set_pressed_no_signal(_value)
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
		unmark_changed()
		value_reverted_to_initial.emit()
	else:
		mark_changed()


func get_edited_property_value() -> Variant:
	return value


func apply_value_to_initial() -> void:
	super()
	_initial_value = value


func revert_to_default() -> void:
	value = _default_value
	super()


func revert_to_initial() -> void:
	value = _initial_value
	super()


func _on_check_box_pressed() -> void:
	check_box.remove_theme_icon_override(&"unchecked")


func _on_check_box_toggled(toggled_on: bool) -> void:
	if undo_redo:
		var property_name: StringName = label.text.to_lower()
		undo_redo.create_action("Set value for bool property " + property_name)
		undo_redo.add_do_property(self, &"value", toggled_on)
		undo_redo.add_undo_property(self, &"value", value)
		undo_redo.commit_action()
	else:
		value = toggled_on
