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
	line_edit.text_submitted.connect(_on_contorller_value_changed)


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


func set_value(_value: String) -> void:
	if is_instance_valid(line_edit) and not line_edit.text == _value:
		if not line_edit.text_changed.is_connected(set_value):
			line_edit.text = _value
		else:
			line_edit.text_changed.disconnect(set_value)
			line_edit.text = _value
			line_edit.text_changed.connect(set_value)
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


func _on_contorller_value_changed(_value: String) -> void:
	if undo_redo:
		var property_name: StringName = label.text.to_lower()
		undo_redo.create_action("Set value for String property " + property_name)
		undo_redo.add_do_property(self, &"value", _value)
		undo_redo.add_undo_property(self, &"value", value)
		undo_redo.commit_action()
	else:
		value = _value
