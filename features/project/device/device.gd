@tool
class_name Device
extends Node2D


enum DeviceFunction {
	PRIMARY,
	TRANSMITTER,
}
static var device_function_tag: Dictionary[DeviceFunction, String] = {
	DeviceFunction.PRIMARY: "E",
	DeviceFunction.TRANSMITTER: "T"
}
@export var device_data: DeviceData
@onready var tag_label: Label = $TagLabel
@onready var suffix_label: Label = $SuffixLabel


func _ready() -> void:
	device_data.tag_changed.connect(_on_device_data_tag_changed)
	tag_label.text = device_data.tag
	if Engine.is_editor_hint():
		EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)


func _on_device_data_tag_changed() -> void:
	set_tag_label_text()


func set_tag_label_text() -> void:
	tag_label.text = device_data.get_mesurand_tag() + device_data.get_device_function()
	suffix_label.text = str(device_data.suffix)


func _on_selection_changed() -> void:
	pass
	#if self in EditorInterface.get_selection().get_selected_nodes():
		#gizmo_manager.show_gizmos()
	#else:
		#gizmo_manager.hide_gizmos()
