@tool
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
	var hint_string: String = _property[&"hint_string"]
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
	
	if hint_string.contains("suffix:"):
		var suffix: String = hint_string.split("suffix:")[1]
		spin_box.suffix = suffix.strip_edges()


func set_value(_value: int) -> void:
	if value == _value:
		return
	if undo_redo and not _property.is_empty():
		var property_name: StringName = _property[&"name"]
		undo_redo.create_action("Set value for int property " + property_name)
		undo_redo.add_do_property(self, &"value", _value)
		undo_redo.add_undo_property(self, &"value", value)
		undo_redo.commit_action()
	else:
		value = _value
	value_changed.emit()
	if is_instance_valid(spin_box) and not spin_box.value == value:
		spin_box.set_value_no_signal(value)
	if is_instance_valid(revert_button):
		if not value == _default_value:
			show_revert_button()
		else:
			hide_revert_button()


func _on_revert_button_pressed() -> void:
	value = _default_value
	hide_revert_button()


func _on_spin_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if not mouse_button_event.is_command_or_control_pressed():
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spin_box.value = spin_box.value + spin_box.step
		elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spin_box.value = spin_box.value - spin_box.step
