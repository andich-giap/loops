@icon("res://addons/at-icons/control/sliders.svg")
class_name PropertyEditContainer
extends VBoxContainer


signal property_changed(property_edit: PropertyEdit)
signal property_reverted_to_initial_value(property_edit: PropertyEdit)
signal property_reverted_to_default_value(property_edit: PropertyEdit)
const BOOL_PROPERTY_EDIT: PackedScene = preload("uid://xbmy05ggemo5")
const INT_PROPERTY_EDIT: PackedScene = preload("uid://b6yqnxwkvbm7w")
const FLOAT_PROPERTY_EDIT: PackedScene = preload("uid://cnfgfwaw7ccev")
const STRING_PROPERTY_EDIT: PackedScene = preload("uid://cwu8tmnkvwrsr")
const COLOR_PROPERTY_EDIT: PackedScene = preload("uid://lxt7r1fdl2h8")
const ENUM_PROPERTY_EDIT: PackedScene = preload("uid://cqhvswx4xnxih")
var property_edits: Array[PropertyEdit]
var theme_property_edits: Dictionary[Theme.DataType, Array]
var changed_properties: Array[PropertyEdit]
var changed_theme_properties: Dictionary[Theme.DataType, Array]
var _undo_redo: UndoRedo = UndoRedo.new()
var _has_undo_focus: bool = false
@onready var header: HSplitContainer = %Header
@export var undo_shortcut: Shortcut


func _ready() -> void:
	theme_type_variation = &"PropertyEditContainer"
	header.dragged.connect(_on_header_dragged)
	mouse_entered.connect(func() -> void: _has_undo_focus = true)
	mouse_exited.connect(func() -> void: _has_undo_focus = false)


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
			property_edit = BOOL_PROPERTY_EDIT.instantiate()
		Variant.Type.TYPE_INT:
			var hint: PropertyHint = property[&"hint"]
			if hint == PROPERTY_HINT_ENUM:
				property_edit = ENUM_PROPERTY_EDIT.instantiate()
			else:
				property_edit = INT_PROPERTY_EDIT.instantiate()
		Variant.Type.TYPE_FLOAT:
			property_edit = FLOAT_PROPERTY_EDIT.instantiate()
		Variant.Type.TYPE_STRING:
			property_edit = STRING_PROPERTY_EDIT.instantiate()
		Variant.Type.TYPE_COLOR:
			property_edit = COLOR_PROPERTY_EDIT.instantiate()
		_:
			push_warning("Property of type " + str(property_type) + " is not supported")
			return
	
	property_edit.undo_redo = undo_redo
	property_edits.append(property_edit)
	add_child(property_edit)
	property_edit.split_offsets = header.split_offsets
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
			property_edit = COLOR_PROPERTY_EDIT.instantiate()
		Theme.DATA_TYPE_CONSTANT:
			return
			#property_edit = CONSTANT_PROPERTY_EDIT.instantiate()
		Theme.DATA_TYPE_FONT:
			return
			#property_edit = FONT_PROPERTY_EDIT.instantiate()
		Theme.DATA_TYPE_FONT_SIZE:
			property_edit = INT_PROPERTY_EDIT.instantiate()
		Theme.DATA_TYPE_ICON:
			return
			#property_edit = ICON_PROPERTY_EDIT.instantiate()
		Theme.DATA_TYPE_STYLEBOX:
			return
			#property_edit = STYLEBOX_PROPERTY_EDIT.instantiate()
	
	property_edit.undo_redo = undo_redo
	property_edit.split_offsets = header.split_offsets
	if not theme_property_edits.has(property_data_type):
		theme_property_edits[property_data_type] = []
	theme_property_edits[property_data_type].append(property_edit)
	add_child(property_edit)
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
		property_edit.queue_free()
	property_edits.clear()
	changed_properties.clear()
	for property_edit_list: Array in theme_property_edits.values():
		for property_edit: PropertyEdit in property_edit_list:
			property_edit.queue_free()
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


func _on_header_dragged(_offset: int) -> void:
	for property_edit: PropertyEdit in property_edits:
		property_edit.split_offsets = header.split_offsets
	for property_list: Array in theme_property_edits.values():
		for property_edit: PropertyEdit in property_list:
			property_edit.split_offsets = header.split_offsets


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
