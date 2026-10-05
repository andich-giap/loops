@tool
class_name DeviceData
extends Resource


signal tag_changed()
@export var mesurand: Units.Mesurand:
	set = set_mesurand
@export var device_function: Device.DeviceFunction = Device.DeviceFunction.TRANSMITTER:
	set = set_device_function
@export var suffix: int = 0:
	set = set_suffix
@export var tag: StringName:
	set = set_tag
@export var override_tag: bool = false:
	set = set_override_tag


func _init() -> void:
	_update_tag()
	tag_changed.emit.call_deferred()


func set_mesurand(_mesurand: Units.Mesurand) -> void:
	mesurand = _mesurand
	_update_tag()


func set_device_function(_device_function: Device.DeviceFunction) -> void:
	device_function = _device_function
	_update_tag()


func set_suffix(_suffix: int) -> void:
	suffix = _suffix
	_update_tag()


func set_override_tag(_override_tag: bool) -> void:
	override_tag = _override_tag
	notify_property_list_changed()
	_update_tag()


func set_tag(_tag: StringName) -> void:
	tag = _tag
	notify_property_list_changed()
	tag_changed.emit()


func _update_tag() -> void:
	if override_tag:
		return
	tag = str(
		Units.mesurand_tag[mesurand]
		+ Device.device_function_tag[device_function]
		+ str(suffix)
	)


func _validate_property(property: Dictionary) -> void:
	if property["name"] == "tag" and not override_tag:
		property["usage"] |= PROPERTY_USAGE_READ_ONLY


func get_mesurand_tag() -> String:
	return Units.mesurand_tag[mesurand]


func get_device_function() -> String:
	return Device.device_function_tag[device_function]
	
