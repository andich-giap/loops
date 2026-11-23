class_name EnumPropertyEdit
extends PropertyEdit


@export var value: int = 0:
	set = set_value
var _initial_value: int
var _default_value: int
var _values: PackedStringArray
var option_button: OptionButton


func set_property(object: Object, property: Dictionary, is_multivalue: bool = false) -> void:
	super(object, property, is_multivalue)
	var hint_string: String = property[&"hint_string"]
	var property_name: StringName = property[&"name"]
	
	var default_value: Variant = _get_property_default_value(object, property_name)
	if not typeof(default_value) == TYPE_NIL:
		_default_value = default_value
	
	value = object.get(property_name)
	_initial_value = value
	unmark_changed()
	
	_values = hint_string.split(",")
	
	for enum_name: StringName in _values:
		var value_name: StringName = enum_name
		if value_name.contains(":"):
			value_name = enum_name.split(":")[0]
		value_name = value_name.to_snake_case().to_upper()
		option_button.add_item(value_name)
	
	if is_multivalue:
		_mark_multivalue()
	else:
		option_button.select(value)


func set_value(_value: int) -> void:
	if is_instance_valid(option_button) \
		and not _is_multivalue \
		and option_button.has_selectable_items() \
		and not option_button.selected == _value \
		and option_button.item_count - 1 >= _value:
		option_button.set_block_signals(true)
		option_button.select(_value)
		option_button.set_block_signals(false)
	
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


func _on_option_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if not mouse_button_event.pressed or not mouse_button_event.is_command_or_control_pressed():
			return
		
		var max_valid_index: int = option_button.item_count - 1
		if max_valid_index >= 0 and option_button.get_item_text(max_valid_index) == "<...>":
			max_valid_index -= 1
		if max_valid_index < 0:
			return
		
		var current: int = option_button.selected
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var next_idx: int = 0 if current < 0 or current >= max_valid_index else current + 1
			_on_controller_value_changed(next_idx)
		elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var prev_idx: int = max_valid_index if current <= 0 or current > max_valid_index else current - 1
			_on_controller_value_changed(prev_idx)


func _on_controller_value_changed(_value: int) -> void:
	_commit_value(_value, &"enum")


func _mark_multivalue() -> void:
	_unmark_multivalue()
	option_button.add_item("<...>", option_button.item_count)
	option_button.set_block_signals(true)
	option_button.select(option_button.item_count - 1)
	option_button.set_block_signals(false)


func _unmark_multivalue() -> void:
	for i: int in range(option_button.item_count - 1, -1, -1):
		if option_button.get_item_text(i) == "<...>":
			option_button.remove_item(i)


func _create_control() -> Control:
	option_button = OptionButton.new()
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	option_button.item_selected.connect(_on_controller_value_changed)
	option_button.gui_input.connect(_on_option_button_gui_input)
	
	return option_button
