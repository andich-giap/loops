@tool
class_name PropertyContainer
extends HBoxContainer


signal changed(new_value: Variant)
var label: Label
var property: Dictionary:
	set = set_property
var column_width: float = 10.0:
	set = set_column_width
var value: Variant:
	set = set_value
var value_node: Control
var is_enum: bool = false
var is_changed: bool = false
var has_multiple_values: bool = false
var theme_callable: StringName


func _ready() -> void:
	if not label:
		label = Label.new()
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS_FORCE
		label.custom_minimum_size.x = column_width
		if property:
			set_label_text()
		add_child(label)
	if not property:
		return
	value_node = _create_property_control(property)


func _create_property_control(_property: Dictionary) -> Control:
	var type: Variant.Type = property["type"]
	var control: Control
	match type:
		TYPE_BOOL:
			var check_box: CheckBox = CheckBox.new()
			check_box.button_pressed = value
			control = check_box
			check_box.toggled.connect(_on_value_node_value_changed)
			if has_multiple_values:
				self_modulate = Color(1.0, 1.0, 1.0, 0.5)
		TYPE_FLOAT:
			var line_edit: LineEdit = LineEdit.new()
			line_edit.text = str(value)
			control = line_edit
			line_edit.text_changed.connect(_on_value_node_value_changed)
			if has_multiple_values:
				line_edit.text = "..."
		TYPE_INT:
			if is_enum:
				var option_button: OptionButton = OptionButton.new()
				var enumeration: String = property["hint_string"]
				for key: String in enumeration.split(","):
					option_button.add_item(key.split(":")[0])
				var index: int = value
				if has_multiple_values:
					option_button.add_item("...")
					option_button.select(option_button.item_count - 1)
				else:
					option_button.select(index)
				control = option_button
				option_button.item_selected.connect(_on_value_node_value_changed)
			else:
				var spin_box: SpinBox = SpinBox.new()
				spin_box.value = value
				spin_box.allow_greater = true
				spin_box.allow_lesser = true
				control = spin_box
				spin_box.value_changed.connect(_on_value_node_value_changed)
				if has_multiple_values:
					spin_box.self_modulate = Color(1.0, 1.0, 1.0, 0.5)
		TYPE_COLOR:
			var color_picker_button: ColorPickerButton = ColorPickerButton.new()
			color_picker_button.color = value
			control = color_picker_button
			color_picker_button.color_changed.connect(_on_value_node_value_changed)
			if has_multiple_values:
				color_picker_button.self_modulate = Color(1.0, 1.0, 1.0, 0.5)
		TYPE_STRING:
			var line_edit: LineEdit = LineEdit.new()
			line_edit.text = str(value)
			control = line_edit
			line_edit.text_changed.connect(_on_value_node_value_changed)
			if has_multiple_values:
				line_edit.text = "..."
		TYPE_STRING_NAME:
			var line_edit: LineEdit = LineEdit.new()
			line_edit.text = str(value)
			control = line_edit
			line_edit.text_changed.connect(_on_value_node_value_changed)
			if has_multiple_values:
				line_edit.text = "..."
		_:
			printerr("Property of type %s is not supported" % type)
			return
	add_child(control)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_FILL
	return control


func set_column_width(_column_width: float) -> void:
	column_width = _column_width
	if label:
		label.custom_minimum_size.x = column_width


func set_property(_property: Dictionary) -> void:
	property = _property
	if property["type"] == TYPE_INT and not property["hint_string"] == "":
		is_enum = true
	else:
		is_enum = false
	if label:
		set_label_text()
	if value_node:
		value_node.queue_free()
		value_node = _create_property_control(property)


func set_value(_value: Variant) -> void:
	if not property:
		value = _value
		return
	match property["type"]:
		TYPE_FLOAT:
			var float_value: float
			if typeof(_value) == TYPE_STRING:
				@warning_ignore("unsafe_call_argument")
				float_value = float(_value)
			else:
				float_value = _value
			value = float(float_value)
		_:
			value = _value


func set_label_text() -> void:
	var property_name: StringName = property["name"]
	label.text = property_name.to_upper()


func _on_value_node_value_changed(_value: Variant) -> void:
	value_node.self_modulate = Color.WHITE
	if is_enum:
		var option_button: OptionButton = value_node
		var last_item: int = option_button.item_count - 1
		if option_button.get_item_text(last_item) == "..." \
			and not last_item == option_button.selected:
			option_button.remove_item(last_item)
	is_changed = true
	value = _value
	changed.emit(value)
