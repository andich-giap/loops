@icon("res://addons/at-icons/control/sliders.svg")
class_name PropertyEditContainer
extends HSplitContainer


signal property_changed(property_edit: PropertyEdit)
signal property_reverted_to_initial_value(property_edit: PropertyEdit)
signal property_reverted_to_default_value(property_edit: PropertyEdit)
var property_edits: Array[PropertyEdit]
var theme_property_edits: Dictionary[Theme.DataType, Array]
var changed_properties: Array[PropertyEdit]
var changed_theme_properties: Dictionary[Theme.DataType, Array]
var _undo_redo: UndoRedo = UndoRedo.new()
@onready var property_labels_v_box_container: VBoxContainer = %PropertyLabelsVBoxContainer
@onready var property_values_v_box_container: VBoxContainer = %PropertyValuesVBoxContainer


func _ready() -> void:
	theme_type_variation = &"PropertyEditContainer"
	var drag_area_controls: Array[Control] = get_drag_area_controls()
	for column: int in range(drag_area_controls.size()):
		drag_area_controls[column].gui_input.connect(_on_drag_area_control_gui_input.bind(column))


func _shortcut_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not get_global_rect().has_point(get_global_mouse_position()):
		return
	if event.is_action_pressed(&"ui_undo"):
		_undo_redo.undo()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_redo"):
		_undo_redo.redo()
		get_viewport().set_input_as_handled()


func add_property(object: Object,
	property: Dictionary,
	is_multivalue: bool = false,
	undo_redo: UndoRedo = _undo_redo,
) -> PropertyEdit:
	var property_type: Variant.Type = property[&"type"]
	
	var property_edit: PropertyEdit
	match property_type:
		Variant.Type.TYPE_BOOL:
			property_edit = BoolPropertyEdit.new()
		Variant.Type.TYPE_INT:
			var hint: PropertyHint = property[&"hint"]
			if hint == PROPERTY_HINT_ENUM:
				property_edit = EnumPropertyEdit.new()
			else:
				property_edit = IntPropertyEdit.new()
		Variant.Type.TYPE_FLOAT:
			property_edit = FloatPropertyEdit.new()
		Variant.Type.TYPE_STRING:
			property_edit = StringPropertyEdit.new()
		Variant.Type.TYPE_COLOR:
			property_edit = ColorPropertyEdit.new()
		_:
			push_warning("Property of type " + str(property_type) + " is not supported")
			return
	
	property_edits.append(property_edit)
	property_edit.undo_redo = undo_redo
	property_labels_v_box_container.add_child(property_edit.label_container)
	property_values_v_box_container.add_child(property_edit.control)
	property_edit.set_property(object, property, is_multivalue)
	
	property_edit.value_changed.connect(_on_property_edit_changed, CONNECT_APPEND_SOURCE_OBJECT)
	property_edit.value_reverted_to_initial.connect(_on_property_edit_reverted_to_initial, CONNECT_APPEND_SOURCE_OBJECT)
	
	property_edit.value_changed.connect(property_changed.emit.unbind(1), CONNECT_APPEND_SOURCE_OBJECT)
	property_edit.value_reverted_to_initial.connect(property_reverted_to_initial_value.emit, CONNECT_APPEND_SOURCE_OBJECT)
	property_edit.value_reverted_to_default.connect(property_reverted_to_default_value.emit, CONNECT_APPEND_SOURCE_OBJECT)
	
	return property_edit


func add_theme_property(
	control: Control,
	property_data_type: Theme.DataType,
	property_name: StringName,
	is_multivalue: bool = false,
	undo_redo: UndoRedo = _undo_redo,
) -> PropertyEdit:
	var property_edit: PropertyEdit
	
	match property_data_type:
		Theme.DATA_TYPE_COLOR:
			property_edit = ColorPropertyEdit.new()
		Theme.DATA_TYPE_CONSTANT:
			property_edit = IntPropertyEdit.new()
		Theme.DATA_TYPE_FONT:
			return
			#property_edit = IntPropertyEdit.new()
		Theme.DATA_TYPE_FONT_SIZE:
			property_edit = IntPropertyEdit.new()
		Theme.DATA_TYPE_ICON:
			return
			#property_edit = ICON_PROPERTY_EDIT.instantiate()
		Theme.DATA_TYPE_STYLEBOX:
			return
			#property_edit = STYLEBOX_PROPERTY_EDIT.instantiate()
	
	if not theme_property_edits.has(property_data_type):
		theme_property_edits[property_data_type] = []
	theme_property_edits[property_data_type].append(property_edit)
	
	property_edit.undo_redo = undo_redo
	
	property_labels_v_box_container.add_child(property_edit.label_container)
	property_values_v_box_container.add_child(property_edit.control)
	
	property_edit.set_theme_property(
		control,
		property_data_type,
		property_name,
		is_multivalue
	)
	
	property_edit.value_changed.connect(_on_theme_property_edit_changed.bind(property_data_type, property_edit).unbind(1))
	property_edit.value_reverted_to_initial.connect(_on_theme_property_edit_reverted_to_initial.bind(property_data_type, property_edit))
	
	property_edit.value_changed.connect(property_changed.emit.unbind(1), CONNECT_APPEND_SOURCE_OBJECT)
	property_edit.value_reverted_to_initial.connect(property_reverted_to_initial_value.emit, CONNECT_APPEND_SOURCE_OBJECT)
	property_edit.value_reverted_to_default.connect(property_reverted_to_default_value.emit, CONNECT_APPEND_SOURCE_OBJECT)
	
	return property_edit


func get_property_of_class(property_class: StringName, property_name: StringName) -> Dictionary:
	var property_list: Array[Dictionary]
	if ClassDB.class_exists(property_class):
		property_list = ClassDB.class_get_property_list(property_class)
	else:
		for class_entry: Dictionary in ProjectSettings.get_global_class_list():
			if class_entry[&"name"] == property_class:
				var script_path: String = class_entry[&"path"]
				var script: Script = load(script_path)
				property_list = script.get_script_property_list()
	for property: Dictionary in property_list:
		if property[&"name"] == property_name:
			return property
	return {}


func clear() -> void:
	for property_edit: PropertyEdit in property_edits:
		property_edit.label_container.queue_free()
		property_edit.control.queue_free()
	property_edits.clear()
	changed_properties.clear()
	for property_edit_list: Array in theme_property_edits.values():
		for property_edit: PropertyEdit in property_edit_list:
			property_edit.label_container.queue_free()
			property_edit.control.queue_free()
	theme_property_edits.clear()
	changed_theme_properties.clear()


func clear_changed() -> void:
	for property_edit: PropertyEdit in changed_properties:
		property_edit.unmark_changed()
	changed_properties.clear()
	for property_list: Array in changed_theme_properties.values():
		for property_edit: PropertyEdit in property_list:
			property_edit.unmark_changed()
	changed_theme_properties.clear()


func apply_values_to_initial() -> void:
	for property_edit: PropertyEdit in changed_properties:
		property_edit.apply_value_to_initial()
	changed_properties.clear()
	for property_list: Array in changed_theme_properties.values():
		for property_edit: PropertyEdit in property_list:
			property_edit.apply_value_to_initial()
	changed_theme_properties.clear()


func _on_property_edit_changed(_value: Variant, property_edit: PropertyEdit) -> void:
	if changed_properties.has(property_edit):
		return
	changed_properties.append(property_edit)


func _on_property_edit_reverted_to_initial(property_edit: PropertyEdit) -> void:
	changed_properties.erase(property_edit)


func _on_theme_property_edit_changed(property_data_type: Theme.DataType, property_edit: PropertyEdit) -> void:
	if changed_theme_properties.has(property_data_type) \
		and changed_theme_properties[property_data_type].has(property_edit):
			return
	if not changed_theme_properties.has(property_data_type):
		changed_theme_properties[property_data_type] = []
	changed_theme_properties[property_data_type].append(property_edit)


func _on_theme_property_edit_reverted_to_initial(property_data_type: Theme.DataType, property_edit: PropertyEdit) -> void:
	if not changed_theme_properties.has(property_data_type) \
		or not changed_theme_properties[property_data_type].has(property_edit):
			return
	changed_theme_properties[property_data_type].erase(property_edit)
	if changed_theme_properties[property_data_type].is_empty():
		changed_theme_properties.erase(property_data_type)


func fit_column(column: int) -> void:
	var minimum_width: int = 0
	var initial_text_overrun_behavior: TextServer.OverrunBehavior
	var initial_shrink_flags_horizontal: int
	var initial_clip_text: bool
	
	for property_edit: PropertyEdit in property_edits:
		if column == 0:
			initial_text_overrun_behavior = property_edit.label.text_overrun_behavior
			initial_shrink_flags_horizontal = property_edit.label.size_flags_horizontal
			initial_clip_text = property_edit.label.clip_text
			var initial_text: String = property_edit.label.text
			
			property_edit.label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			property_edit.label.text = TranslationServer.translate(property_edit.label.text)
			property_edit.label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			property_edit.label.clip_text = false
			property_edit.label.update_minimum_size()
			var current_minimum_width: int = int(property_edit.label_container.get_combined_minimum_size().x)
			
			property_edit.label.text = initial_text
			property_edit.label.size_flags_horizontal = initial_shrink_flags_horizontal
			property_edit.label.clip_text = initial_clip_text
			property_edit.label.update_minimum_size()
			
			if is_instance_valid(property_edit.revert_button):
				current_minimum_width += int(property_edit.revert_button.get_combined_minimum_size().x)
			print(current_minimum_width)
			minimum_width = maxi(minimum_width, current_minimum_width)
	
	var header_label: Label = get_child(column).get_child(0)
	
	initial_text_overrun_behavior = header_label.text_overrun_behavior
	initial_shrink_flags_horizontal = header_label.size_flags_horizontal
	initial_clip_text = header_label.clip_text
	
	header_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	header_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	header_label.clip_text = false
	
	header_label.update_minimum_size()
	minimum_width = maxi(minimum_width, int(header_label.get_combined_minimum_size().x))
	
	header_label.text_overrun_behavior = initial_text_overrun_behavior
	header_label.size_flags_horizontal = initial_shrink_flags_horizontal
	header_label.clip_text = initial_clip_text
	header_label.update_minimum_size()
	
	if minimum_width > 0:
		var new_split_offsets: PackedInt32Array = split_offsets
		new_split_offsets[column] = minimum_width
		split_offsets = new_split_offsets


func _on_drag_area_control_gui_input(event: InputEvent, column: int) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.double_click and mouse_button_event.pressed:
			fit_column(column)
