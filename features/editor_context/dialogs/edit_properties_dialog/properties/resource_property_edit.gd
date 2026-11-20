class_name ResourcePropertyEdit
extends PropertyEdit


const PREVIEW_SIZE: Vector2i = Vector2i(100, 18)
@export var value: Resource = null:
	set = set_value
var _initial_value: Resource
var _default_value: Resource
var option_button: OptionButton
var viewports: Dictionary[int, Viewport]


func set_property(object: Object, property: Dictionary, is_multivalue: bool = false) -> void:
	super(object, property, is_multivalue)
	var _class_name: String = property[&"class_name"]
	var property_name: StringName = property[&"name"]
	
	var default_value: Variant = _get_property_default_value(object, property_name)
	if not typeof(default_value) == TYPE_NIL:
		_default_value = default_value
	
	value = object.get(property_name)
	_initial_value = value
	unmark_changed()
	
	var valid_resources: Array[Resource] = SettingsManager.get_resources(_class_name)
	_populate_options(valid_resources)
	option_button.select(get_resource_id(value))
	
	if is_multivalue:
		_mark_multivalue()
	
	if not _default_value:
		hide_revert_button()


func set_theme_property(
	themed_control: Control,
	property_data_type: Theme.DataType,
	property_name: StringName,
	is_multivalue: bool = false
) -> void:
	super(themed_control, property_data_type, property_name, is_multivalue)
	
	var theme_type: StringName = themed_control.theme_type_variation
	var resource_class: StringName
	
	if not theme_type:
		theme_type = themed_control.get_class()
	
	var property_theme: Theme = _get_theme(themed_control)
	if property_data_type == Theme.DataType.DATA_TYPE_FONT \
		and property_theme.has_font(property_name, theme_type):
			_default_value = property_theme.get_font(property_name, theme_type)
			resource_class = &"Font"
	elif property_data_type == Theme.DataType.DATA_TYPE_ICON \
		and property_theme.has_icon(property_name, theme_type):
			_default_value = property_theme.get_icon(property_name, theme_type)
			resource_class = &"Texture2D"
	elif property_data_type == Theme.DataType.DATA_TYPE_STYLEBOX \
		and property_theme.has_stylebox(property_name, theme_type):
			_default_value = property_theme.get_stylebox(property_name, theme_type)
			resource_class = &"StyleBox"
	
	if property_data_type == Theme.DataType.DATA_TYPE_FONT:
		value = themed_control.get_theme_font(property_name, theme_type)
	elif property_data_type == Theme.DataType.DATA_TYPE_ICON:
		value = themed_control.get_theme_icon(property_name, theme_type)
	elif property_data_type == Theme.DataType.DATA_TYPE_STYLEBOX:
		value = themed_control.get_theme_stylebox(property_name, theme_type)
	else:
		push_warning(" ".join([
			"Trying to assign property",
			property_name,
			"with Theme.DataType",
			str(property_data_type),
			"to a IntPropertyEdit"
		]))
		return
	_initial_value = value
	unmark_changed()
	
	var valid_resources: Array[Resource] = SettingsManager.get_resources(resource_class)
	_populate_options(valid_resources)
	option_button.select(get_resource_id(value))
	
	if is_multivalue:
		_mark_multivalue()


func set_value(_value: Resource) -> void:
	if is_instance_valid(option_button) \
		and not _is_multivalue \
		and option_button.has_selectable_items() \
		and not option_button.get_item_metadata(option_button.selected) == _value:
		option_button.set_block_signals(true)
		option_button.select(get_resource_id(_value))
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
	_commit_value(_default_value, "int")
	super()


func revert_to_initial() -> void:
	_commit_value(_initial_value, "int")
	super()


func _on_spin_box_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if not mouse_button_event.is_command_or_control_pressed():
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_on_controller_value_changed(int(option_button.selected + 1))
		elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_on_controller_value_changed(int(option_button.selected - 1))


func _on_controller_value_changed(_value: int) -> void:
	_commit_value(option_button.get_item_metadata(_value), &"Resource")


func _mark_multivalue() -> void:
	_unmark_multivalue()
	#var line: LineEdit = spin_box.get_line_edit()
	#line.set_block_signals(true)
	#line.text = ""
	#line.set_block_signals(false)
	#line.placeholder_text = "<...>"


func _unmark_multivalue() -> void:
	pass
	#spin_box.get_line_edit().placeholder_text = ""


func _create_control() -> Control:
	option_button = OptionButton.new()
	option_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	option_button.clip_text = true
	
	option_button.get_popup().index_pressed.connect(_on_controller_value_changed)
	option_button.gui_input.connect(_on_spin_box_gui_input)
	
	return option_button


func get_resource_id(resource: Resource) -> int:
	for i: int in range(option_button.item_count):
		if option_button.get_item_metadata(i) == resource:
			return i
	return -1


func _populate_options(resources: Array[Resource]) -> void:
	option_button.clear()
	for id: int in range(resources.size()):
		var resource: Resource = resources[id]
		if not resources[id]:
			continue
		var resource_name: StringName = resource.resource_path.get_file().get_basename()
		resource_name = resource_name.to_snake_case().to_upper()
		
		if resource is SystemFont:
			var system_font: SystemFont = resource
			resource_name = system_font.font_names[0]
		
		option_button.add_item(resource_name, id)
		option_button.set_item_metadata(id, resources[id])
		_create_preview(id, PREVIEW_SIZE)


func _create_preview(id: int, size: Vector2i) -> void:
	var resource: Resource = option_button.get_item_metadata(id)
	if not resource:
		return
	var preview_node: Node = _get_preview(size, resource)
	if not preview_node:
		return
	
	var viewport: SubViewport = SubViewport.new()
	
	if viewports.has(id):
		viewports[id].queue_free()
	
	viewports[id] = viewport
	viewport.add_child(preview_node)
	viewport.size = size
	viewport.transparent_bg = true
	option_button.add_child(viewport)
	
	if is_instance_valid(viewport):
		option_button.set_item_icon(id, viewport.get_texture())


func _get_preview(size: Vector2, resource: Resource) -> Node:
	var resource_class: StringName = resource.get_class()
	var script: GDScript = resource.get_script()
	if script:
		resource_class = script.get_global_name()
	match resource_class:
		&"LineStyle":
			var poly_line_2d: PolyLine2D = PolyLine2D.new()
			poly_line_2d.line_style = resource
			poly_line_2d.decoration_size = 1.0
			poly_line_2d.add_point(Vector2(0.0, size.y / 2.0))
			poly_line_2d.add_point(Vector2(size.x, size.y / 2.0))
			return poly_line_2d
		
		_:
			return
