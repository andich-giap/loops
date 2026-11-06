@icon("res://addons/at-icons/node/text_input.svg")
@abstract
class_name PropertyEdit
extends RefCounted


@warning_ignore_start("unused_signal")
signal value_changed(new_value: Variant) ## Emittet when the value is changed.
signal value_reverted_to_default() ## Emitted when value is restored to class default value.
signal value_reverted_to_initial() ## Emitted when value is restored to initial value.
@warning_ignore_restore("unused_signal")
var label_container: HBoxContainer
var label: Label
var control: Control
var undo_redo: UndoRedo
var _is_multivalue: bool
var revert_button: Button


func _init() -> void:
	label_container = HBoxContainer.new()
	
	label = Label.new()
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND
	label.theme_type_variation = &"PropertyEditLabel"
	label_container.add_child(label)
	
	revert_button = Button.new()
	revert_button.icon = preload("uid://dakpo2wi68qu5")
	revert_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	revert_button.flat = true
	revert_button.tooltip_text = "REVERT_PROPERTY_TO_DEFAULT"
	revert_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	revert_button.visible = false
	label_container.add_child(revert_button)
	
	control = _create_control()


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
	_is_multivalue = is_multivalue


@warning_ignore("unused_parameter")
func set_theme_property(
	theme_control: Control,
	property_data_type: Theme.DataType,
	property_name: StringName,
	is_multivalue: bool = false
) -> void:
	label.text = property_name.to_upper()
	_is_multivalue = is_multivalue


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


func _get_theme(theme_control: Control) -> Theme:
	var property_theme: Theme = theme_control.theme
	if not property_theme:
		property_theme = ThemeDB.get_project_theme()
	if not property_theme:
		property_theme = ThemeDB.get_default_theme()
	return property_theme


func _get_property_default_value(object: Object, property_name: StringName) -> Variant:
	if object.get_script():
		var script: Script = object.get_script()
		return script.get_property_default_value(property_name)
	else:
		var property_class: StringName = object.get_class()
		var default_value: Variant = ClassDB.class_get_property_default_value(property_class, property_name)
		if not typeof(default_value) == TYPE_NIL:
			return default_value
		return null


func _commit_value(_value: Variant, type: StringName) -> void:
	var old_value: Variant = get(&"value")
	var old_is_multivalue: bool = _is_multivalue

	if undo_redo:
		undo_redo.create_action(
			"Set value for %s property %s" % [type, get_property_name()],
			UndoRedo.MERGE_ENDS
		)
		undo_redo.add_do_method(_apply_state.bind(_value, false))
		undo_redo.add_undo_method(_apply_state_no_signal.bind(old_value, old_is_multivalue))
		undo_redo.commit_action()
	else:
		_apply_state(_value, false)


func _apply_state(_value: Variant, was_multivalue: bool) -> void:
	_apply_state_visual(_value, was_multivalue)
	value_changed.emit(_value)


func _apply_state_no_signal(_value: Variant, was_multivalue: bool) -> void:
	_apply_state_visual(_value, was_multivalue)


func _apply_state_visual(_value: Variant, was_multivalue: bool) -> void:
	if _is_multivalue != was_multivalue:
		_is_multivalue = was_multivalue
		if was_multivalue:
			_mark_multivalue()
		else:
			_unmark_multivalue()
	set(&"value", _value)


@abstract
func _mark_multivalue() -> void


@abstract
func _unmark_multivalue() -> void


@abstract
func _create_control() -> Control
