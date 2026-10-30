class_name EnumPropertyEdit
extends PropertyEdit


@export var value: int = 0:
	set = set_value
var _initial_value: int
var _default_value: int
var _values: PackedStringArray
@onready var options_button: OptionButton = %OptionsButton


func _ready() -> void:
	super()
	options_button.item_selected.connect(_on_controller_value_changed)
	options_button.gui_input.connect(_on_options_button_gui_input)


func set_property(object: Object, property: Dictionary, is_multivalue: bool = false) -> void:
	super(object, property, is_multivalue)
	var hint_string: String = property[&"hint_string"]
	var property_name: StringName = property[&"name"]
	
	value = object.get(property_name)
	_initial_value = value
	unmark_changed()
	
	var default_value: Variant = _get_property_default_value(object, property_name)
	if not typeof(default_value) == TYPE_NIL:
		_default_value = default_value
	
	_values = hint_string.split(",")
	
	for enum_name: StringName in _values:
		options_button.add_item(enum_name)
	
	if is_multivalue:
		_mark_multivalue()


func set_value(_value: int) -> void:
	if is_instance_valid(options_button) \
		and not _is_multivalue \
		and options_button.has_selectable_items() \
		and not options_button.selected == _value \
		and options_button.item_count - 1 >= _value:
		options_button.set_block_signals(true)
		options_button.select(_value)
		options_button.set_block_signals(false)
	
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
	_commit_value(_default_value, "enum")
	super()


func revert_to_initial() -> void:
	_commit_value(_initial_value, "enum")
	super()


func _on_options_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if not mouse_button_event.is_command_or_control_pressed():
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			options_button.select(mini(value + 1, _values.size() - 1))
		elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			options_button.select(maxi(value - 1, 0))


func _on_controller_value_changed(_value: int) -> void:
	_commit_value(_value, &"enum")


func _mark_multivalue() -> void:
	_unmark_multivalue()
	options_button.add_item("<...>", options_button.item_count)
	options_button.set_block_signals(true)
	options_button.select(options_button.item_count - 1)
	options_button.set_block_signals(false)


func _unmark_multivalue() -> void:
	for i: int in range(options_button.item_count - 1, -1, -1):
		if options_button.get_item_text(i) == "<...>":
			options_button.remove_item(i)
