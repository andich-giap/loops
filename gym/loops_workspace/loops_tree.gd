@tool
class_name LoopsTree
extends Tree


var designations: Array[Designation]
var loops_tree_item: TreeItem
var devices_tree_item: TreeItem


func _ready() -> void:
	var root: TreeItem = create_item()
	loops_tree_item = create_item(root)
	loops_tree_item.set_text(0, "Loops")
	devices_tree_item = create_item(root)
	devices_tree_item.set_text(0, "Devices")
	cell_selected.connect(_on_cell_selected)


func _can_drop_data(at_position: Vector2, _data: Variant) -> bool:
	var tree_item: TreeItem = get_item_at_position(at_position)
	if not tree_item:
		return false
	var metadata: Variant = tree_item.get_metadata(0)
	if not metadata or metadata is not Resource:
		return false
	if metadata is LoopData:
		var loop_data: LoopData = metadata
		if _data is DeviceData:
			var device_data: DeviceData = _data
			if not device_data in loop_data.device_datas:
				return true
	return false


func _get_drag_data(at_position: Vector2) -> Variant:
	var tree_item: TreeItem = get_item_at_position(at_position)
	if not tree_item:
		return
	var metadata: Variant = tree_item.get_metadata(0)
	if metadata is Resource:
		var texture: TextureRect = TextureRect.new()
		texture.texture = Texture.new()
		set_drag_preview(texture)
		return metadata
	else:
		return null


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var tree_item: TreeItem = get_item_at_position(at_position)
	var metadata: Variant = tree_item.get_metadata(0)
	if metadata is LoopData and data is DeviceData:
		var loop_data: LoopData = metadata
		var device_data: DeviceData = data
		loop_data.add_device(device_data)


func _on_cell_selected() -> void:
	var tree_item: TreeItem = get_selected()
	var metadata: Variant = tree_item.get_metadata(0)
	if metadata is Resource:
		var resource: Resource = metadata
		if Engine.is_editor_hint():
			EditorInterface.edit_resource(resource)
