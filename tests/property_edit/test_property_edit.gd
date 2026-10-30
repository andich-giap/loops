extends Control


@export var test_control: Control
@onready var property_edit_container: PropertyEditContainer = %PropertyEditContainer


func _ready() -> void:
	if not test_control:
		test_control = Button.new()
	
	var properties: Array[Dictionary] = get_test_properties()
	for property: Dictionary in properties:
		var property_edit: PropertyEdit = property_edit_container.add_property(test_control, property, true)
		if not property_edit:
			continue
		property_edit.split_offsets = property_edit_container.header.split_offsets
	
	var theme_properties: Dictionary[Theme.DataType, Array] = get_test_theme_properties()
	for property: Theme.DataType in theme_properties.keys():
		for property_name: StringName in theme_properties[property]:
			var property_edit: PropertyEdit = property_edit_container.add_theme_property(
				test_control,
				property,
				property_name,
				true
			)
			if not property_edit:
				continue
			property_edit.split_offsets = property_edit_container.header.split_offsets


func get_test_properties() -> Array[Dictionary]:
	var property_names: Array[StringName] = [
		&"propagate_maximum_size", # bool
		&"z_index", # int
		&"rotation", # rotation + property hint range
		&"text", # String
		&"self_modulate", # Color
		&"clip_children", # enum
	]
	var properties: Array[Dictionary]
	
	for property: Dictionary in test_control.get_property_list():
		if property_names.has(property[&"name"]):
			properties.append(property)
			if property_names.size() == properties.size():
				break
	
	return properties


func get_test_theme_properties() -> Dictionary[Theme.DataType, Array]:
	var theme_property_names: Dictionary[Theme.DataType, Array] = {
		Theme.DATA_TYPE_COLOR: [
			&"font_color",
			&"font_focus_color"
		],
		Theme.DATA_TYPE_CONSTANT: [
			&"h_separation",
		],
		Theme.DATA_TYPE_FONT: [
			&"font",
		],
		Theme.DATA_TYPE_FONT_SIZE: [
			&"font_size",
		],
		Theme.DATA_TYPE_ICON: [
			&"icon",
		],
		Theme.DATA_TYPE_STYLEBOX: [
			&"normal",
		],
	}
	
	return theme_property_names


func _apply() -> void:
	for property: PropertyEdit in property_edit_container.changed_properties:
		test_control.set(property.get_property_name(), property.get_edited_property_value())
	for property_data_type: Theme.DataType in property_edit_container.changed_theme_properties.keys():
		for property: PropertyEdit in property_edit_container.changed_theme_properties[property_data_type]:
			match property_data_type:
				Theme.DataType.DATA_TYPE_COLOR:
					var value: Color = property.get_edited_property_value()
					test_control.add_theme_color_override(property.get_property_name(), value)
				Theme.DATA_TYPE_CONSTANT:
					var value: int = property.get_edited_property_value()
					test_control.add_theme_constant_override(property.get_property_name(), value)
				Theme.DATA_TYPE_FONT:
					var value: Font = property.get_edited_property_value()
					test_control.add_theme_font_override(property.get_property_name(), value)
				Theme.DATA_TYPE_FONT_SIZE:
					var value: int = property.get_edited_property_value()
					test_control.add_theme_font_size_override(property.get_property_name(), value)
				Theme.DATA_TYPE_ICON:
					var value: Texture2D = property.get_edited_property_value()
					test_control.add_theme_icon_override(property.get_property_name(), value)
				Theme.DATA_TYPE_STYLEBOX:
					var value: StyleBox = property.get_edited_property_value()
					test_control.add_theme_stylebox_override(property.get_property_name(), value)
	property_edit_container.apply_values_to_initial()
