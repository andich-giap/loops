class_name FloatPropertyEdit
extends PropertyEdit


const RADIANS_TO_DEGREES: float = 180.0 / PI
@export var value: float = 0.0:
	set = set_value
var _initial_value: float
var _default_value: float
var _display_scale: float = 1.0
@onready var spin_box: SpinBox = %SpinBox


func _ready() -> void:
	super()
	var line_edit: LineEdit = spin_box.get_line_edit()
	line_edit.theme_type_variation = &"PropertyLineEdit"
	
	spin_box.value_changed.connect(_on_controller_value_changed)
	spin_box.gui_input.connect(_on_spin_box_gui_input)


func set_property(object: Object, property: Dictionary, is_multivalue: bool = false) -> void:
	super(object, property, is_multivalue)
	var hint: PropertyHint = property[&"hint"]
	var hint_string: String = property[&"hint_string"]
	var property_name: StringName = property[&"name"]
	
	if hint == PropertyHint.PROPERTY_HINT_RANGE:
		var hints: PackedStringArray = hint_string.split(",")
		spin_box.min_value = hints[0].to_float()
		spin_box.max_value = hints[1].to_float()
		if hints.size() >= 3 and hints[2].is_valid_float():
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
			_display_scale = RADIANS_TO_DEGREES
		if hints[-1].begins_with("suffix"):
			var suffix: String = hints[-1].split("suffix:")[1]
			spin_box.suffix = suffix.strip_edges()
	elif hint_string.contains(","):
		var hints: PackedStringArray = hint_string.split(",")
		for hint_part: String in hints:
			if hint_part.begins_with("suffix:"):
				spin_box.suffix = hint_part.split("suffix:")[1].strip_edges()
	elif hint_string.begins_with("suffix"):
		var suffix: String = hint_string.split("suffix:")[1]
		spin_box.suffix = suffix.strip_edges()
	
	value = object.get(property_name)
	_initial_value = value
	unmark_changed()
	
	var default_value: Variant = _get_property_default_value(object, property_name)
	if not typeof(default_value) == TYPE_NIL:
		_default_value = default_value
	
	if is_multivalue:
		_mark_multivalue()


func set_value(_value: float) -> void:
	if is_instance_valid(spin_box) and not _is_multivalue \
		and not is_equal_approx(spin_box.value, _value * _display_scale):
		spin_box.set_value_no_signal(_value * _display_scale)
	
	if is_instance_valid(revert_button):
		if _is_multivalue or not _value == _default_value:
			show_revert_button()
		else:
			hide_revert_button()
	
	if is_equal_approx(value, _value):
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
	_commit_value(_default_value, "float")
	super()


func revert_to_initial() -> void:
	_commit_value(_initial_value, "float")
	super()


func _on_spin_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if not mouse_button_event.is_command_or_control_pressed():
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_on_controller_value_changed(spin_box.value + spin_box.step)
		elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_on_controller_value_changed(spin_box.value - spin_box.step)


func _on_controller_value_changed(_value: float) -> void:
	_value = _value / _display_scale
	_commit_value(_value, &"float")


func _mark_multivalue() -> void:
	_unmark_multivalue()
	var line: LineEdit = spin_box.get_line_edit()
	line.set_block_signals(true)
	line.text = ""
	line.set_block_signals(false)
	line.placeholder_text = "<...>"


func _unmark_multivalue() -> void:
	spin_box.get_line_edit().placeholder_text = ""
