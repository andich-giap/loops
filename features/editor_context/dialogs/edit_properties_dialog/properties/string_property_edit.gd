class_name StringPropertyEdit
extends PropertyEdit


@export var value: String = "":
	set = set_value
var _initial_value: String
var _default_value: String
@onready var line_edit: LineEdit = %LineEdit


func _ready() -> void:
	super()
	line_edit.text_submitted.connect(_on_controller_value_changed)
	line_edit.focus_exited.connect(_on_controller_value_changed)


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


func set_value(_value: String) -> void:
	if is_instance_valid(line_edit) and not _is_multivalue and not line_edit.text == _value:
		line_edit.set_block_signals(true)
		line_edit.text = _value
		line_edit.set_block_signals(false)
	
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
	_commit_value(_default_value, "String")
	super()


func revert_to_initial() -> void:
	_commit_value(_initial_value, "String")
	super()


func _on_controller_value_changed(_value: String = line_edit.text) -> void:
	if not value == _value:
		_commit_value(_value, &"String")


func _mark_multivalue() -> void:
	_unmark_multivalue()
	line_edit.set_block_signals(true)
	line_edit.text = ""
	line_edit.set_block_signals(false)
	line_edit.placeholder_text = "<...>"


func _unmark_multivalue() -> void:
	line_edit.placeholder_text = ""
