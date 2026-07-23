@tool
extends Control


var loop_datas: Array[LoopData]
var device_datas: Array[DeviceData]
var designations: Array[Designation]
@onready var loops_tree: LoopsTree = $TabContainer/LoopsManager/PanelContainer2/Panel/LoopsTree


func _on_new_loop_button_pressed() -> void:
	var loop_data: LoopData = LoopData.new()
	loop_datas.append(loop_data)
	var loop_data_tree_item: TreeItem = loops_tree.create_item(loops_tree.loops_tree_item)
	loop_data_tree_item.set_metadata(0, loop_data)
	loop_data.name_changed.connect(_on_data_name_changed.bind(loop_data_tree_item, loop_data))
	if Engine.is_editor_hint():
		EditorInterface.edit_resource(loop_data)


func _on_new_device_button_pressed() -> void:
	var device_data: DeviceData = DeviceData.new()
	device_datas.append(device_data)
	var device_data_tree_item: TreeItem = loops_tree.create_item(loops_tree.devices_tree_item)
	device_data_tree_item.set_metadata(0, device_data)
	device_data.tag_changed.connect(_on_data_name_changed.bind(device_data_tree_item, device_data))
	if Engine.is_editor_hint():
		EditorInterface.edit_resource(device_data)


func _on_data_name_changed(tree_item: TreeItem, data: Resource) -> void:
	if data is LoopData:
		var loop_data: LoopData = data
		tree_item.set_text(0, loop_data.name)
	if data is DeviceData:
		var device_data: DeviceData = data
		tree_item.set_text(0, device_data.tag)


func _on_reload_button_pressed() -> void:
	get_tree().reload_current_scene()
