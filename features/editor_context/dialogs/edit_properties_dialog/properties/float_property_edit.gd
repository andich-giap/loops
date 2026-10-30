class_name FloatPropertyEdit
extends PropertyEdit


var RADIANS_TO_DEGREES_PROPORTION: float = PI / 180.0
@export var value: float = 0.0:
	set = set_value
var _initial_value: float
var _default_value: float
var _proportion_multiplier: float = 1.0
@onready var spin_box: SpinBox = %SpinBox


func _ready() -> void:
	super()
	var line_edit: LineEdit = spin_box.get_line_edit()
	line_edit.theme_type_variation = &"PropertyLineEdit"
	
	spin_box.value_changed.connect(_on_contorller_value_changed)
	spin_box.gui_input.connect(_on_spin_box_gui_input)


func set_property(object: Object, property: Dictionary, is_multivalue: bool = false) -> void:
	super(object, property, is_multivalue)
	var hint: PropertyHint = property[&"hint"]
	var hint_string: String = property[&"hint_string"]
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
	
	if hint_string.begins_with("suffix"):
		var suffix: String = hint_string.split("suffix:")[1]
		spin_box.suffix = suffix.strip_edges()
	
	if hint == PropertyHint.PROPERTY_HINT_RANGE:
		var hints: PackedStringArray = hint_string.split(",")
		spin_box.min_value = hints[0].to_float()
		spin_box.max_value = hints[1].to_float()
		spin_box.step = hints[2].to_float()
		if hints.has("or_less"):
			spin_box.allow_lesser = true
		else:
			spin_box.allow_lesser = false
		if hints.has("or_greater"):
			spin_box.allow_greater = true
		else:
			spin_box.allow_greater = false
		if hints[-1] == "radians_as_degrees":
			spin_box.suffix = "°"
			_proportion_multiplier = RADIANS_TO_DEGREES_PROPORTION


func set_value(_value: float) -> void:
	if is_instance_valid(spin_box) and not spin_box.value == _value:
		spin_box.set_value_no_signal(_value)
	_value = _value * _proportion_multiplier
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


func _on_spin_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if not mouse_button_event.is_command_or_control_pressed():
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spin_box.value = spin_box.value + spin_box.step
		elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spin_box.value = spin_box.value - spin_box.step


func _on_contorller_value_changed(_value: float) -> void:
	if undo_redo:
		var property_name: StringName = label.text.to_lower()
		undo_redo.create_action("Set value for float property " + property_name)
		undo_redo.add_do_property(self, &"value", _value)
		undo_redo.add_undo_property(self, &"value", value)
		undo_redo.commit_action()
	else:
		value = _value
