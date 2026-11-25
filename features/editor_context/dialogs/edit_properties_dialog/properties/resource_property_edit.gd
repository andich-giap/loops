class_name ResourcePropertyEdit
extends PropertyEdit


const PREVIEW_SIZE: Vector2i = Vector2i(100, 18)
@export var value: Resource = null:
	set = set_value
var _initial_value: Resource
var _default_value: Resource
var option_button: OptionButton
var _preview_viewport: SubViewport
var _populate_generation: int = 0
static var _preview_cache: Dictionary[Resource, ImageTexture]


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
	
	_setup_preview_vieport()
	
	var valid_resources: Array[Resource] = SettingsManager.get_resources(_class_name)
	_populate_options(valid_resources)
	
	if is_multivalue:
		_mark_multivalue()
	else:
		option_button.select(get_resource_id(value))
		
	if not _default_value:
		hide_revert_button()
		
	_populate_generation += 1
	await _bake_all_previews(_populate_generation)


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
	
	_setup_preview_vieport()
	
	
	var valid_resources: Array[Resource] = SettingsManager.get_resources(resource_class)
	_populate_options(valid_resources)
	
	if is_multivalue:
		_mark_multivalue()
	else:
		option_button.select(get_resource_id(value))
		
	if not _default_value:
		hide_revert_button()
		
	_populate_generation += 1
	await _bake_all_previews(_populate_generation)


func set_value(_value: Resource) -> void:
	if _value is SystemFont:
		var system_font: SystemFont = _value
		_value = SettingsManager.get_system_font(system_font.font_names[0])
	
	if is_instance_valid(option_button) \
		and not _is_multivalue \
		and option_button.has_selectable_items() \
		and not option_button.get_selected_metadata() == _value:
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


func _setup_preview_vieport() -> void:
	if not _preview_viewport:
		_preview_viewport = SubViewport.new()
		_preview_viewport.transparent_bg = true
		_preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		option_button.add_child(_preview_viewport)
	_preview_viewport.size = PREVIEW_SIZE


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


func get_resource_id(resource: Resource) -> int:
	for i: int in range(option_button.item_count):
		var meta: Resource = option_button.get_item_metadata(i)
		if meta == resource:
			return i
	return -1


func _on_controller_value_changed(index: int) -> void:
	if not is_instance_valid(option_button) or index < 0 or index >= option_button.item_count:
		return
	
	if option_button.get_item_text(index) == "<...>":
		return
	
	var selected_resource: Resource = option_button.get_item_metadata(index)
	
	_unmark_multivalue()
	var valid_id: int = get_resource_id(selected_resource)
	if valid_id >= 0:
		option_button.set_block_signals(true)
		option_button.select(valid_id)
		option_button.set_block_signals(false)
	
	_commit_value(selected_resource, &"Resource")


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


func _create_control() -> Control:
	option_button = OptionButton.new()
	option_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	option_button.clip_text = true
	option_button.search_bar_enabled = true
	option_button.search_bar_fuzzy_search_enabled = true
	
	option_button.get_popup().index_pressed.connect(_on_controller_value_changed)
	option_button.gui_input.connect(_on_option_button_gui_input)
	
	return option_button


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


func _bake_node_texture(preview_node: Node) -> ImageTexture:
	_preview_viewport.add_child(preview_node)
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	await RenderingServer.frame_post_draw
	
	if not is_instance_valid(_preview_viewport):
		return
	var img: Image = _preview_viewport.get_texture().get_image()
	_preview_viewport.remove_child(preview_node)
	preview_node.queue_free()
	
	return ImageTexture.create_from_image(img)


func _create_preview(id: int, size: Vector2i) -> void:
	if id < 0 or not is_instance_valid(option_button):
		return
	
	var resource: Resource = option_button.get_item_metadata(id)
	if not resource:
		return
	
	if _preview_cache.has(resource):
		option_button.set_item_icon(id, _preview_cache[resource])
		return
	
	var preview_node: Node = _get_preview(size, resource)
	if not preview_node:
		return
	
	var preview: ImageTexture = await _bake_node_texture(preview_node)
	
	if preview:
		_preview_cache[resource] = preview
		option_button.set_item_icon(id, preview)


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
		
		&"SystemFont":
			var font: SystemFont = resource as SystemFont
			var font_name: String = font.font_names[0]
			var node_2d: Node2D = Node2D.new()
			node_2d.draw.connect(
				node_2d.draw_string.bind(
					font,
					Vector2(0.0, size.y * 0.75),
					font_name,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					16,
					Color.BLACK
				)
			)
			return node_2d
		
		_:
			return


func _bake_all_previews(gen: int) -> void:
	var priority_id: int = option_button.selected
	if priority_id >= 0:
		await _create_preview(priority_id, PREVIEW_SIZE)
		
	for id: int in range(option_button.item_count):
		if not gen == _populate_generation or not is_instance_valid(option_button):
			return
		if id == priority_id:
			continue
		await _create_preview(id, PREVIEW_SIZE)
