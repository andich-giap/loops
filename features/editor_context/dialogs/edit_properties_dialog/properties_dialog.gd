class_name PropertiesDialog
extends ConfirmationDialog
## Dialog that is used to edit the properties of the selected contents.


#const DOUBLE_CLICK_INTERVAL: float = 0.4
#var _max_size: Vector2i
#var _double_click_timer: Timer
var _edit_properties_callable: Callable
var _apply_changes_callable: Callable
@onready var property_edit_container: PropertyEditContainer = %PropertyEditContainer
@onready var choose_item_to_edit_dialog: ConfirmationDialog = %ChooseItemToEditDialog ## A dialog that shows which node type to edit. The node type is determined by class.
@onready var scripts_tree: Tree = %ScriptsTree ## Reference to scripts tree.


func _ready() -> void:
	move_to_center()
	canceled.connect(_on_canceled)
	
	#_double_click_timer = Timer.new()
	#_double_click_timer.one_shot = true
	#_double_click_timer.wait_time = DOUBLE_CLICK_INTERVAL
	#add_child(_double_click_timer)


## Shows the dialog and edits selected nodes. 
func activate(nodes_to_edit: Array[Node]) -> void:
	if nodes_to_edit.is_empty():
		return
	edit_properties(nodes_to_edit)


## Triggers the edit of the properties of specified [param edited_nodes].
func edit_properties(edited_nodes: Array[Node]) -> void:
	clear_properties()
	if edited_nodes.is_empty():
		return
	
	var properties: Array[Dictionary] = get_properties(edited_nodes)
	var properties_per_class: Dictionary[Script, Array] = properties[0]
	var theme_properties_per_class: Dictionary[Script, Dictionary] = properties[1]
	if properties_per_class.size() > 1:
		scripts_tree.clear()
		var tree_root: TreeItem = scripts_tree.create_item()
		
		for script: Script in properties_per_class:
			var tree_item: TreeItem = scripts_tree.create_item(tree_root)
			tree_item.set_metadata(0, script)
			tree_item.set_text(0, script.get_global_name().to_snake_case().to_upper())
		
		scripts_tree.set_selected(scripts_tree.get_root().get_child(0), 0)
		choose_item_to_edit_dialog.show()
		
		_edit_properties_callable = _select_and_edit_properties.bind(
			edited_nodes,
			properties_per_class,
			theme_properties_per_class
		)
		choose_item_to_edit_dialog.confirmed.connect(_edit_properties_callable)
		scripts_tree.item_activated.connect(_edit_properties_callable)
		return
	
	var script: Script = properties_per_class.keys()[0]
	var valid_nodes: Array[Node] = get_valid_nodes(edited_nodes, script)
	_instanciate_properties_of_script(
		valid_nodes,
		script,
		properties_per_class,
		theme_properties_per_class
	)
	size.y = 0
	show()


## Gets editable properties of specified [param edited_nodes].
func get_properties(edited_nodes: Array[Node]) -> Array[Dictionary]:
	var properties_per_class: Dictionary[Script, Array]
	var theme_properties_per_class: Dictionary[Script, Dictionary] = {}
	for node: Node in edited_nodes:
		var _script: Variant = node.get_script()
		if not _script:
			continue
		var script: Script = _script
		var property_list: Array[Dictionary]
		var theme_property_list: Dictionary[Theme.DataType, Array]
		if node.has_method(&"get_editable_properties"):
			property_list = node.call(&"get_editable_properties")
		if node.has_method(&"_validate_property"):
			for property: Dictionary in property_list:
				node.call(&"_validate_property", property)
		else:
			property_list = script.get_script_property_list()
		if node.has_method(&"get_theme_overridable_properties"):
			theme_property_list = node.call(&"get_theme_overridable_properties")
			theme_properties_per_class[script] = theme_property_list
		for property: Dictionary in property_list:
			if property["usage"] & PROPERTY_USAGE_EDITOR:
				if not properties_per_class.has(script):
					properties_per_class[script] = []
				if properties_per_class[script].has(property):
					continue
				properties_per_class[script].append(property)
	return [properties_per_class, theme_properties_per_class]


## Returns nodes of a corresponding [param script].
func get_valid_nodes(edited_nodes: Array[Node], script: Script) -> Array[Node]:
	return edited_nodes.filter(
		func(node: Node) -> bool:
			return node.get_script() == script
	)


## Clears instanciated properties.
func clear_properties() -> void:
	property_edit_container.clear()
	scripts_tree.clear()


## Applies changes that were made in the dialog to the [param edited_nodes].
func apply_changes(edited_nodes: Array[Node]) -> void:
	confirmed.disconnect(_apply_changes_callable)
	_apply_changes_callable = Callable()
	for node: Node in edited_nodes:
		for property: PropertyEdit in property_edit_container.changed_properties:
			node.set(property.get_property_name(), property.get_edited_property_value())
		if node is not Control:
			continue
		for data_type: Theme.DataType in property_edit_container.changed_theme_properties:
			for theme_property_edit: PropertyEdit in property_edit_container.theme_property_edits[data_type]:
				var control: Control = node
				match data_type:
					Theme.DataType.DATA_TYPE_COLOR:
						var color: Color = theme_property_edit.get_edited_property_value()
						control.add_theme_color_override(
							theme_property_edit.get_property_name(),
							color
						)
					Theme.DataType.DATA_TYPE_CONSTANT:
						var constant: int = theme_property_edit.get_edited_property_value()
						control.add_theme_constant_override(
							theme_property_edit.get_property_name(),
							constant
						)
					Theme.DataType.DATA_TYPE_FONT:
						var font: Font = theme_property_edit.get_edited_property_value()
						control.add_theme_font_override(
							theme_property_edit.get_property_name(),
							font
						)
					Theme.DataType.DATA_TYPE_FONT_SIZE:
						var font_size: int = theme_property_edit.get_edited_property_value()
						control.add_theme_font_size_override(
							theme_property_edit.get_property_name(),
							font_size
						)
					Theme.DataType.DATA_TYPE_ICON:
						var icon: Texture2D = theme_property_edit.get_edited_property_value()
						control.add_theme_icon_override(
							theme_property_edit.get_property_name(),
							icon
						)
					Theme.DataType.DATA_TYPE_STYLEBOX:
						var stylebox: StyleBox = theme_property_edit.get_edited_property_value()
						control.add_theme_stylebox_override(
							theme_property_edit.get_property_name(),
							stylebox
						)
	property_edit_container.apply_values_to_initial()
	clear_properties()


## Fits a column to the width of the longest value.
func fit_column(column_index: int) -> void:
	pass
	#var controls: Array[Control]
	#controls.append(header.get_child(column_index))
	#for node: Node in properties_container.get_children():
		#if node.get_child(column_index) is not Control:
			#continue
		#controls.append(node.get_child(column_index))
	#
	#for control: Control in controls:
		#if control is Label:
			#var label: Label = control
			#label.custom_minimum_size.x = 0.0
			#label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			#label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			#label.update_minimum_size()
	#
	#controls.sort_custom(func(a: Control, b: Control) -> bool:
		#if a.get_combined_minimum_size().x > b.get_combined_minimum_size().x:
			#return true
		#return false
	#)
	#var split_offsets: PackedInt32Array = header.split_offsets
	#split_offsets[column_index] = int(controls[0].get_combined_minimum_size().x)
	#header.split_offsets = split_offsets
	#header.dragged.emit(split_offsets[0])
	#for control: Control in controls:
		#if control is Label:
			#var label: Label = control
			#label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS_FORCE
			#label.size_flags_horizontal = Control.SIZE_FILL


func _select_and_edit_properties(
		edited_nodes: Array[Node],
		properties_per_class: Dictionary[Script, Array],
		theme_properties_per_class: Dictionary[Script, Dictionary]
	) -> void:
	var script: Script = scripts_tree.get_selected().get_metadata(0)
	var valid_nodes: Array[Node] = get_valid_nodes(edited_nodes, script)
	_instanciate_properties_of_script(
		valid_nodes,
		script,
		properties_per_class,
		theme_properties_per_class
	)
	choose_item_to_edit_dialog.hide()
	size.y = 0
	show()
	
	choose_item_to_edit_dialog.confirmed.disconnect(_edit_properties_callable)
	scripts_tree.item_activated.disconnect(_edit_properties_callable)
	_edit_properties_callable = Callable()


## Instanciates properties of [param edited_nodes].
func _instanciate_properties_of_script(
		edited_nodes: Array[Node],
		script: Script,
		properties_per_class: Dictionary[Script, Array],
		theme_properties_per_class: Dictionary[Script, Dictionary]
	) -> void:
	for property: Dictionary in properties_per_class[script]:
		var property_name: StringName = property["name"]
		property_edit_container.add_property(
			edited_nodes[0],
			property,
			_is_multivalue_property(edited_nodes, property_name),
		)
	if theme_properties_per_class.has(script):
		var theme_properties: Dictionary[Theme.DataType, Array] = theme_properties_per_class[script]
		for theme_data_type: Theme.DataType in theme_properties:
			for theme_property: StringName in theme_properties[theme_data_type]:
				property_edit_container.add_theme_property(
					edited_nodes[0] as Control,
					theme_data_type,
					theme_property,
					_is_multivalue_theme_property(edited_nodes, theme_property, theme_data_type)
				)
	fit_column(0)
	_apply_changes_callable = apply_changes.bind(edited_nodes)
	confirmed.connect(_apply_changes_callable)


func _is_multivalue_property(edited_nodes: Array[Node], property_name: StringName) -> bool:
	var value: Variant = edited_nodes[0].get(property_name)
	for node: Node in edited_nodes:
		if not node.get(property_name) == value:
			return true
	return false


func _is_multivalue_theme_property(
	edited_nodes: Array[Node],
	theme_property_name: StringName,
	data_type: Theme.DataType
) -> bool:
	var value: Variant
	var control: Control = edited_nodes[0]
	var type_variation: StringName = control.theme_type_variation
	if type_variation == "":
		type_variation = control.get_class()
	match data_type:
		Theme.DataType.DATA_TYPE_COLOR:
			value = control.get_theme_color(theme_property_name, type_variation)
		Theme.DataType.DATA_TYPE_CONSTANT:
			value = control.get_theme_constant(theme_property_name, type_variation)
		Theme.DataType.DATA_TYPE_FONT:
			value = control.get_theme_font(theme_property_name, type_variation)
		Theme.DataType.DATA_TYPE_FONT_SIZE:
			value = control.get_theme_font_size(theme_property_name, type_variation)
		Theme.DataType.DATA_TYPE_ICON:
			value = control.get_theme_icon(theme_property_name, type_variation)
		Theme.DataType.DATA_TYPE_STYLEBOX:
			value = control.get_theme_stylebox(theme_property_name, type_variation)
	
	for node: Node in edited_nodes:
		control = node
		type_variation = control.theme_type_variation
		if type_variation == "":
			type_variation = control.get_class()
		var current_value: Variant
		match data_type:
			Theme.DataType.DATA_TYPE_COLOR:
				current_value = control.get_theme_color(theme_property_name, type_variation)
			Theme.DataType.DATA_TYPE_CONSTANT:
				current_value = control.get_theme_constant(theme_property_name, type_variation)
			Theme.DataType.DATA_TYPE_FONT:
				current_value = control.get_theme_font(theme_property_name, type_variation)
			Theme.DataType.DATA_TYPE_FONT_SIZE:
				current_value = control.get_theme_font_size(theme_property_name, type_variation)
			Theme.DataType.DATA_TYPE_ICON:
				current_value = control.get_theme_icon(theme_property_name, type_variation)
			Theme.DataType.DATA_TYPE_STYLEBOX:
				current_value = control.get_theme_stylebox(theme_property_name, type_variation)
		if not current_value == value:
			return true
	return false


#func _on_header_drag_started() -> void:
	#if _double_click_timer.is_stopped():
		#_max_size = max_size
		#max_size = size
		#_double_click_timer.start()
	#else:
		#fit_column(0)
		#_double_click_timer.stop()


func _on_canceled() -> void:
	clear_properties()
	if confirmed.is_connected(_apply_changes_callable):
		confirmed.disconnect(_apply_changes_callable)
