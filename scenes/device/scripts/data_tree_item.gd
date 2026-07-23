@tool
class_name DataTreeItem
extends TreeItem


func set_data(data: Resource) -> void:
	set_metadata(0, data)


func get_data() -> Resource:
	return get_metadata(0)


func _get_drag_data(_at_position: Vector2) -> Variant:
	var data: Resource = get_data()
	if data:
		return data
	else:
		return


func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	var data: Resource = get_data()
	if not data:
		return false
	if data is LoopData:
		if _data is DeviceData:
			return true
	return false


func _drop_data(_at_position: Vector2, _data: Variant) -> void:
	var data: Resource = get_data()
	if data is LoopData and _data is Device:
		var loop_data: LoopData = data
		var device_data: DeviceData = _data
		loop_data.add_device(device_data)
