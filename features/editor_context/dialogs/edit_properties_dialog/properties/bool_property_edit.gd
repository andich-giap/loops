class_name BoolPropertyEdit
extends PropertyEdit


@export var value: bool = false:
	set = set_value
var _initial_value: bool
var _default_value: bool
@onready var check_box: CheckBox = %CheckBox


func _ready() -> void:
	super()
	check_box.toggled.connect(_on_controller_value_changed)


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


func set_value(_value: bool) -> void:
	if is_instance_valid(check_box) and not _is_multivalue and not check_box.button_pressed == _value:
		check_box.set_pressed_no_signal(_value)
		
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
	_commit_value(_default_value, "bool")
	super()


func revert_to_initial() -> void:
	_commit_value(_initial_value, "bool")
	super()


func _on_controller_value_changed(toggled_on: bool) -> void:
	_commit_value(toggled_on, &"bool")


func _mark_multivalue() -> void:
	_unmark_multivalue()
	set_block_signals(true)
	check_box.button_pressed = false
	set_block_signals(false)
	check_box.add_theme_icon_override(
		&"unchecked",
		check_box.get_theme_icon(&"multivalue", &"BoolPropertyEditCheckBox")
	)


func _unmark_multivalue() -> void:
	if check_box.has_theme_icon_override(&"unchecked"):
		check_box.remove_theme_icon_override(&"unchecked")
