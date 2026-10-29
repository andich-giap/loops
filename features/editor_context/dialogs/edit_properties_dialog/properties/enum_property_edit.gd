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
	hide_revert_button()
	revert_button.pressed.connect(_on_revert_button_pressed)
	
	options_button.item_selected.connect(_on_contorller_value_changed)
	options_button.gui_input.connect(_on_options_button_gui_input)


func set_property(object: Object, property: Dictionary, is_multivalue: bool = false) -> void:
	super(object, property, is_multivalue)
	var hint_string: String = property[&"hint_string"]
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
	
	_values = hint_string.split(",")
	
	for enum_name: StringName in _values:
		options_button.add_item(enum_name)
	
	if value == _default_value:
		hide_revert_button()


func set_value(_value: int) -> void:
	if is_instance_valid(options_button) and not options_button.selected == _value:
		if not options_button.item_selected.is_connected(set_value):
			if options_button.has_selectable_items() \
				and options_button.item_count - 1 >= _value:
				options_button.select(_value)
		else:
			options_button.item_selected.disconnect(set_value)
			options_button.select(_value)
			options_button.item_selected.connect(set_value)
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


func _on_options_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if not mouse_button_event.is_command_or_control_pressed():
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			options_button.select(mini((value + 1), _values.size() - 1))
		elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			options_button.select(maxi((value - 1), _values.size() - 1))


func _on_contorller_value_changed(_value: int) -> void:
	if undo_redo:
		var property_name: StringName = label.text.to_lower()
		undo_redo.create_action("Set value for enum property " + property_name)
		undo_redo.add_do_property(self, &"value", _value)
		undo_redo.add_undo_property(self, &"value", value)
		undo_redo.commit_action()
	else:
		value = _value
