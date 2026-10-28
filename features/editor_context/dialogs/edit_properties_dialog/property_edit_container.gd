@icon("res://addons/at-icons/control/sliders.svg")
class_name PropertyEditContainer
extends VBoxContainer


const BOOL_PROPERTY_EDIT: PackedScene = preload("uid://xbmy05ggemo5")
const INT_PROPERTY_EDIT: PackedScene = preload("uid://b6yqnxwkvbm7w")
const FLOAT_PROPERTY_EDIT: PackedScene = preload("uid://cnfgfwaw7ccev")
const STRING_PROPERTY_EDIT: PackedScene = preload("uid://cwu8tmnkvwrsr")
const COLOR_PROPERTY_EDIT: PackedScene = preload("uid://lxt7r1fdl2h8")
@onready var header: HSplitContainer = %Header


func add_property(object: Object, property: Dictionary, is_multivalue: bool = false) -> void:
	var property_type: Variant.Type = property[&"type"]
	
	var property_edit: PropertyEdit
	match property_type:
		Variant.Type.TYPE_BOOL:
			property_edit = BOOL_PROPERTY_EDIT.instantiate()
		Variant.Type.TYPE_INT:
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
	
	property_edit.set_property(object, property, is_multivalue)
	
	add_child(property_edit)
