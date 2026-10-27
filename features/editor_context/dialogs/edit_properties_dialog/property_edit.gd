@abstract
class_name PropertyEdit
extends HBoxContainer


@warning_ignore("unused_signal")
signal value_changed(new_value: Variant) ## Emittet when the value is changed.
var _property: Dictionary ## A property, that is usually retrieved via [method Object.get_property_list].
var undo_redo: UndoRedo
@onready var label: Label = %Label


func _ready() -> void:
	if not undo_redo:
		undo_redo = UndoRedo.new()


@warning_ignore("unused_parameter")
func set_property(object: Object, property: Dictionary) -> void:
	_property = property
	var property_name: StringName = _property[&"name"]
	label.text = property_name.to_upper()
