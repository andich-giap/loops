@icon("res://addons/at-icons/control/text_input.svg")
@abstract
class_name PropertyEdit
extends HSplitContainer


@warning_ignore_start("unused_signal")
signal value_changed(new_value: Variant) ## Emittet when the value is changed.
signal value_reverted_to_default() ## Emitted when value is restored to class default value.
signal value_reverted_to_initial() ## Emitted when value is restored to initial value.
@warning_ignore_restore("unused_signal")
var undo_redo: UndoRedo
@onready var label: Label = %Label
@onready var revert_button: Button = %RevertButton


func _ready() -> void:
	unmark_changed()
	if not undo_redo:
		undo_redo = UndoRedo.new()
	hide_revert_button()
	revert_button.pressed.connect(revert_to_default)


@warning_ignore("unused_parameter")
func set_property(object: Object, property: Dictionary, is_multivalue: bool = false) -> void:
	var property_name: StringName = property[&"name"]
	label.text = property_name.to_upper()


@warning_ignore("unused_parameter")
func set_theme_property(
	control: Control,
	property_data_type: Theme.DataType,
	property_name: StringName,
	is_multivalue: bool = false
) -> void:
	label.text = property_name.to_upper()


func hide_revert_button() -> void:
	revert_button.hide()


func show_revert_button() -> void:
	revert_button.show()


@abstract
func get_edited_property_value() -> Variant


func mark_changed() -> void:
	if is_instance_valid(label):
		label.theme_type_variation = &"PropertyEditLabelChanged"


func unmark_changed() -> void:
	if is_instance_valid(label):
		label.theme_type_variation = &"PropertyEditLabel"


func get_property_name() -> StringName:
	return label.text.to_lower()


func apply_value_to_initial() -> void:
	unmark_changed()


func revert_to_default() -> void:
	hide_revert_button()
	value_reverted_to_default.emit()


func revert_to_initial() -> void:
	unmark_changed()


func _get_theme(control: Control) -> Theme:
	var property_theme: Theme = control.theme
	if not property_theme:
		property_theme = ThemeDB.get_project_theme()
	if not property_theme:
		property_theme = ThemeDB.get_default_theme()
	return property_theme
