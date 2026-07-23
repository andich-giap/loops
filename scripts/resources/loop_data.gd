@tool
class_name LoopData
extends Resource


signal name_changed
signal device_data_changed
@export_group("Name")
@export var name: StringName:
	set = set_signal_name
@export var override_name: bool = false:
	set = set_override_name
@export_tool_button("Update Name") var update_name: Callable = _update_name
@export_group("Datas")
@export var alarm_datas: Dictionary[AlarmSafetyData.Setpoint, AlarmSafetyData]
@export var safety_datas: Dictionary[AlarmSafetyData.Setpoint, AlarmSafetyData]
@export var device_datas: Array[DeviceData]
@export var main_device_data: DeviceData


func _init() -> void:
	_update_name()
	device_data_changed.connect(_update_name)
	name_changed.emit.call_deferred()


func _validate_property(property: Dictionary) -> void:
	if property["name"] == "name" and not override_name:
		property["usage"] |= PROPERTY_USAGE_READ_ONLY


func _update_name() -> void:
	if override_name:
		return
	var main_device_mesurand_tag: String = ""
	var main_device_suffix: String
	if main_device_data:
		main_device_mesurand_tag = main_device_data.tag.left(1)
		main_device_suffix = str(main_device_data.suffix)
	name = str(
		main_device_mesurand_tag
		+ main_device_suffix
	)


func set_override_name(_override_name: bool) -> void:
	override_name = _override_name
	notify_property_list_changed()
	_update_name()


func set_signal_name(_name: StringName) -> void:
	name = _name
	notify_property_list_changed()
	name_changed.emit()


func _on_device_datas_size_changed() -> void:
	_update_name()


func add_device(device_data: DeviceData) -> void:
	device_datas.append(device_data)
	device_data_changed.emit()
	if device_datas.size() == 1:
		main_device_data = device_data
		device_data.tag_changed.connect(_update_name)
		_update_name()
