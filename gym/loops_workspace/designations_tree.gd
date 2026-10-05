@tool
class_name DesignationsTree
extends Tree


const PLUS: Texture = preload("uid://di85w4in8gymw")
var designations: Array[Designation]


func _ready() -> void:
	var _root: TreeItem = create_item()
	cell_selected.connect(_on_cell_selected)


func _can_drop_data(at_position: Vector2, _data: Variant) -> bool:
	var tree_item: TreeItem = get_item_at_position(at_position)
	if not tree_item:
		return false
	var metadata: Variant = tree_item.get_metadata(0)
	if not metadata or metadata is not Resource:
		return false
	if metadata is Designation:
		return true
	return false


func _get_drag_data(at_position: Vector2) -> Variant:
	var tree_item: TreeItem = get_item_at_position(at_position)
	if not tree_item:
		return
	var metadata: Variant = tree_item.get_metadata(0)
	if metadata is Resource:
		var texture: TextureRect = TextureRect.new()
		texture.texture = PLUS
		set_drag_preview(texture)
		return metadata
	else:
		return null


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var tree_item: TreeItem = get_item_at_position(at_position)
	var metadata: Variant = tree_item.get_metadata(0)
	if metadata is Designation and data is Designation:
		var data_designation: Designation = data
		var metadata_designation: Designation = metadata


func _on_cell_selected() -> void:
	var tree_item: TreeItem = get_selected()
	var metadata: Variant = tree_item.get_metadata(0)
	if metadata is DesignationsData:
		var designations_data: DesignationsData = metadata
		if Engine.is_editor_hint():
			EditorInterface.edit_resource(designations_data.get_last_designation())
	elif metadata is Resource:
		var resource: Resource = metadata
		if Engine.is_editor_hint():
			EditorInterface.edit_resource(resource)


func get_corresponding_parent_at_item(tree_item: TreeItem, designations_data: DesignationsData) -> TreeItem:
	var selected_designations_data: DesignationsData = tree_item.get_metadata(0)
	var selected_designation: Designation = selected_designations_data.get_last_designation()
	if selected_designation.type < designations_data.get_last_designation().type:
		return tree_item
	var parent_item: TreeItem = tree_item.get_parent()
	if parent_item == get_root():
		return get_root()
	return get_corresponding_parent_at_item(parent_item, designations_data)
