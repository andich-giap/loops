@tool
extends VBoxContainer


const NEW_DESIGNATION_DIALOG: PackedScene = preload("uid://bsl8w74ut4jx4")
@onready var designations_tree: DesignationsTree = $PanelContainer2/Panel/DesignationsTree


func _on_new_designation_button_pressed() -> void:
	var new_designation_dialog: NewDesignationDialog = NEW_DESIGNATION_DIALOG.instantiate()
	add_child(new_designation_dialog)
	new_designation_dialog.show()
	new_designation_dialog.confirmed.connect(_on_new_designation_dialog_confirmed.bind(new_designation_dialog))


func _on_new_designation_dialog_confirmed(new_designation_dialog: NewDesignationDialog) -> void:
	var designation: Designation = Designation.new()
	designation.type = Designation.get_type_by_sign(new_designation_dialog.option_button.get_item_text(new_designation_dialog.option_button.selected))
	designation.name = new_designation_dialog.name_line_edit.text
	designation.description = new_designation_dialog.description_text_edit.text
	var designations_data: DesignationsData = DesignationsData.new()
	var selected_tree_item: TreeItem = designations_tree.get_selected()
	if selected_tree_item and selected_tree_item.get_metadata(0) is DesignationsData:
		var selected_designations_data: DesignationsData = selected_tree_item.get_metadata(0)
		for type: Designation.Type in Designation.Type.values():
			if type > designation.type:
				break
			for selected_designation: Designation in selected_designations_data.designations[type]:
				designations_data.add_designation(selected_designation)
	designations_data.add_designation(designation)
	var designations_data_tree_item: TreeItem
	if selected_tree_item and selected_tree_item.get_metadata(0) is DesignationsData:
		designations_data_tree_item = designations_tree.create_item(designations_tree.get_corresponding_parent_at_item(selected_tree_item, designations_data))
	else:
		designations_data_tree_item = designations_tree.create_item(designations_tree.get_root())
	designations_data_tree_item.set_metadata(0, designations_data)
	designations_data.changed.connect(_on_designations_data_changed.bind(designations_data_tree_item, designations_data))
	designations_data_tree_item.set_text(0, designations_data.get_last_designation_tag())
	designations_data_tree_item.set_tooltip_text(0, designations_data.get_last_designation().description)
	if Engine.is_editor_hint():
		EditorInterface.edit_resource(designation)


func _on_designations_data_changed(designations_data_tree_item: TreeItem, designations_data: DesignationsData) -> void:
	designations_data_tree_item.set_text(0, designations_data.get_last_designation_tag())
	designations_data_tree_item.set_tooltip_text(0, designations_data.get_last_designation().description)
