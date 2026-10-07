class_name PropertiesDialog
extends ConfirmationDialog
## Dialog that is used to edit the properties of the selected contents.


const DOUBLE_CLICK_INTERVAL: float = 0.4
var _max_size: Vector2i
var _changed_property_containers: Array[PropertyContainer]
var _double_click_timer: Timer
var _edit_properties_callable: Callable
var _apply_changes_callable: Callable
@onready var properties_container: VBoxContainer = %PropertiesContainer ## Reference to the [PropertiesContainer].
@onready var header: HSplitContainer = %Header ## Reference to header.
@onready var choose_item_to_edit_dialog: ConfirmationDialog = %ChooseItemToEditDialog ## A dialog that shows which node type to edit. The node type is determined by class.
@onready var scripts_tree: Tree = %ScriptsTree ## Reference to scripts tree.


func _ready() -> void:
	canceled.connect(_on_canceled)
	header.drag_started.connect(_on_header_drag_started)
	header.drag_ended.connect(_on_header_drag_ended)
	
	_double_click_timer = Timer.new()
	_double_click_timer.one_shot = true
	_double_click_timer.wait_time = DOUBLE_CLICK_INTERVAL
	add_child(_double_click_timer)


## Shows the dialog and edits selected nodes. 
func activate(nodes_to_edit: Array[Node] = []) -> void:
	if nodes_to_edit.is_empty():
		nodes_to_edit = get_tree().get_nodes_in_group(&"selection")
	edit_properties(nodes_to_edit)


## Triggers the edit of the properties of specified [param edited_nodes].
func edit_properties(edited_nodes: Array[Node]) -> void:
	clear_properties()
	if edited_nodes.is_empty():
		return
	var properties: Array[Dictionary] = get_properties(edited_nodes)
	var properties_per_class: Dictionary[Script, Array] = properties[0]
	var theme_properties_per_class: Dictionary[Script, Dictionary] = properties[1]
	if not properties_per_class.size() == 1:
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
	show()


## Gets editable properties of specified [param edited_nodes].
func get_properties(edited_nodes: Array[Node]) -> Array[Dictionary]:
	var __properties_per_class: Dictionary[Script, Array]
	var __theme_properties_per_class: Dictionary[Script, Dictionary] = {}
	for node: Node in edited_nodes:
		var _script: Variant = node.get_script()
		if not _script:
			continue
		var script: Script = _script
		var property_list: Array[Dictionary]
		var theme_property_list: Dictionary[StringName, Array]
		if node.has_method("get_editable_properties"):
			property_list = node.call("get_editable_properties")
		else:
			property_list = script.get_script_property_list()
		if node.has_method("get_theme_editable_properties"):
			theme_property_list = node.call("get_theme_editable_properties")
			__theme_properties_per_class[script] = theme_property_list
		for property: Dictionary in property_list:
			if property["usage"] & PROPERTY_USAGE_EDITOR:
				if not __properties_per_class.has(script):
					__properties_per_class[script] = []
				if __properties_per_class[script].has(property):
					continue
				__properties_per_class[script].append(property)
	return [__properties_per_class, __theme_properties_per_class]


## Returns nodes of a corresponding [param script].
func get_valid_nodes(edited_nodes: Array[Node], script: Script) -> Array[Node]:
	return edited_nodes.filter(
		func(node: Node) -> bool:
			return node.get_script() == script
	)


## Returns an array of values by specified [param property] from [param edited_nodes].
func get_property_values(property: Dictionary, edited_nodes: Array[Node]) -> Array[Variant]:
	var values: Array[Variant]
	for node: Node in edited_nodes:
		var property_name: StringName = property["name"]
		values.append(node.get(property_name))
	return values


## Checks if all values in [param values] are equal.
func all_values_equal(values: Array[Variant]) -> bool:
	for index: int in range(values.size()):
		if index == values.size() - 1:
			break
		if not values[index] == values[index + 1]:
			return false
	return true


## Clears instanciated properties.
func clear_properties() -> void:
	for node: Node in properties_container.get_children():
		if node.name == "Header":
			continue
		node.queue_free()
	scripts_tree.clear()
	_changed_property_containers.clear()


## Applies changes that were made in the dialog to the [param edited_nodes].
func apply_changes(edited_nodes: Array[Node]) -> void:
	confirmed.disconnect(_apply_changes_callable)
	_apply_changes_callable = Callable()
	for node: Node in edited_nodes:
		for property_container: PropertyContainer in _changed_property_containers:
			var property_name: StringName = property_container.property["name"]
			if property_container.theme_callable:
				node.call("add"+property_container.theme_callable, property_name, property_container.value)
				continue
			node.set(property_name, property_container.retrieve_value())
		if node.has_signal(&"changed"):
			node.emit_signal(&"changed")
	clear_properties()


## Fits a column to the width of the longest value.
func fit_column(column_index: int) -> void:
	var controls: Array[Control]
	controls.append(header.get_child(column_index))
	for node: Node in properties_container.get_children():
		if node.get_child(column_index) is not Control:
			continue
		controls.append(node.get_child(column_index))
	
	for control: Control in controls:
		if control is Label:
			var label: Label = control
			label.custom_minimum_size.x = 0.0
			label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			label.update_minimum_size()
	
	controls.sort_custom(func(a: Control, b: Control) -> bool:
		if a.get_combined_minimum_size().x > b.get_combined_minimum_size().x:
			return true
		return false
	)
	var split_offsets: PackedInt32Array = header.split_offsets
	split_offsets[column_index] = int(controls[0].get_combined_minimum_size().x)
	header.split_offsets = split_offsets
	header.dragged.emit(split_offsets[0])
	for control: Control in controls:
		if control is Label:
			var label: Label = control
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS_FORCE
			label.size_flags_horizontal = Control.SIZE_FILL


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
		var property_container: PropertyContainer = PropertyContainer.new()
		property_container.property = property
		var property_values: Array[Variant] = get_property_values(property, edited_nodes)
		if not all_values_equal(property_values):
			property_container.has_multiple_values = true
		property_container.value = property_values[0]
		property_container.column_width = header.split_offsets[0]
		properties_container.add_child(property_container)
		property_container.changed.connect(_on_property_container_changed.bind(property_container).unbind(1), CONNECT_ONE_SHOT)
		header.dragged.connect(property_container.set_column_width)
	if theme_properties_per_class.has(script):
		var theme_properties: Dictionary[StringName, Array] = theme_properties_per_class[script]
		for theme_callable: StringName in theme_properties:
			var control: Control = edited_nodes[0]
			for theme_property: StringName in theme_properties[theme_callable]:
				var property_container: PropertyContainer = PropertyContainer.new()
				var theme_property_value: Variant = control.call("get"+theme_callable.replace("_override", ""), theme_property, script.get_global_name())
				property_container.property = _construct_theme_property(theme_property, script.get_global_name(), theme_property_value)
				property_container.value = theme_property_value
				property_container.column_width = header.split_offsets[0]
				property_container.theme_callable = theme_callable
				properties_container.add_child(property_container)
				property_container.changed.connect(_on_property_container_changed.bind(property_container).unbind(1), CONNECT_ONE_SHOT)
				header.dragged.connect(property_container.set_column_width)
	fit_column(0)
	_apply_changes_callable = apply_changes.bind(edited_nodes)
	confirmed.connect(_apply_changes_callable)


func _construct_theme_property(property_name: StringName, _class_name: StringName, property_value: Variant) -> Dictionary:
	var property: Dictionary = {
		"name": property_name,
		"class_name": _class_name,
		"type": typeof(property_value),
		"hint": "",
		"hint_string": "",
		"usage": "",
	}
	return property


func _on_header_drag_started() -> void:
	if _double_click_timer.is_stopped():
		_max_size = max_size
		max_size = size
		header.custom_maximum_size.x = max_size.x
		_double_click_timer.start()
	else:
		fit_column(0)
		_double_click_timer.stop()


func _on_header_drag_ended() -> void:
	max_size = _max_size
	header.custom_maximum_size.x = -1


func _on_property_container_changed(property_container: PropertyContainer) -> void:
	_changed_property_containers.append(property_container)


func _on_canceled() -> void:
	clear_properties()
	if confirmed.is_connected(_apply_changes_callable):
		confirmed.disconnect(_apply_changes_callable)
