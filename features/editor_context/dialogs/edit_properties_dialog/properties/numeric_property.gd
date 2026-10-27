@tool
class_name FloatPropertyEdit
extends PropertyEdit


@export var value: float = 0.0:
	set = set_value
var _initial_value: float = 0.0
var _default_value: float
@export_custom(PROPERTY_HINT_NONE, "suffix: px") var fake_value: float = 1.0
@onready var spin_box: SpinBox = %SpinBox
@onready var revert_button: Button = %RevertButton


func _ready() -> void:
	super()
	revert_button.hide()
	revert_button.pressed.connect(_on_revert_button_pressed)
	
	var line_edit: LineEdit = spin_box.get_line_edit()
	line_edit.theme_type_variation = &"PropertyLineEdit"
	
	spin_box.value_changed.connect(value_changed.emit)
	spin_box.value_changed.connect(set_value)
	
	for prop: Dictionary in get_property_list():
		var prop_name: StringName = prop[&"name"]
		if prop_name == &"fake_value":
			set_property(self, prop)


func set_property(object: Object, property: Dictionary) -> void:
	super(object, property)
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
		revert_button.hide()
	
	if hint_string.contains("suffix:"):
		var suffix: String = hint_string.split("suffix:")[1]
		spin_box.suffix = suffix.strip_edges()


func set_value(_value: float) -> void:
	value = _value
	if is_instance_valid(spin_box):
		spin_box.value = value
	if is_instance_valid(revert_button):
		if not value == _default_value:
			revert_button.show()


func _on_revert_button_pressed() -> void:
	value = _default_value
	revert_button.hide()
