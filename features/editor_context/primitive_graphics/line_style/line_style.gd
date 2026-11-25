@tool
class_name LineStyle
extends Resource


@export_tool_button("Add Line Decoration") var tool_add_line_decoration: Callable = _tool_add_line_decoration
@export_tool_button("Remove Line Decoration") var tool_remove_line_decoration: Callable = _tool_remove_line_decoration
@export var line_style_definition: LineStyleDefinition = preload("uid://djogojtvrl0i5"):
	set = set_line_style_definition
@export var line_decorations: Array[LineDecoration]:
	set = set_line_decorations


func set_line_style_definition(_line_style_definition: LineStyleDefinition) -> void:
	if line_style_definition and line_style_definition.changed.is_connected(changed.emit):
		line_style_definition.changed.disconnect(changed.emit)
	
	line_style_definition = _line_style_definition
	line_style_definition.changed.connect(changed.emit)
	changed.emit()


func set_line_decorations(_line_decorations: Array[LineDecoration]) -> void:
	for line_decoration: LineDecoration in line_decorations:
		if line_decoration and line_decoration.changed.is_connected(changed.emit):
			line_decoration.changed.disconnect(changed.emit)
	line_decorations = _line_decorations
	for line_decoration: LineDecoration in line_decorations:
		line_decoration.changed.connect(changed.emit)
	changed.emit()


func add_line_decoration(line_decoration: LineDecoration) -> void:
	if line_decorations.has(line_decoration):
		return
	line_decoration.changed.connect(changed.emit)
	line_decorations.append(line_decoration)
	changed.emit()
	notify_property_list_changed()


func remove_line_decoration(line_decoration: LineDecoration) -> void:
	if not line_decorations.has(line_decoration):
		return
	line_decoration.changed.disconnect(changed.emit)
	line_decorations.erase(line_decoration)
	changed.emit()
	notify_property_list_changed()


func _tool_add_line_decoration() -> void:
	EditorInterface.popup_quick_open(
		(func(path: String) -> void:
			var line_decoration: LineDecoration = load(path)
			var new_decorations: Array[LineDecoration] = line_decorations.duplicate()
			
			if new_decorations.has(line_decoration):
				return
			new_decorations.append(line_decoration)
			
			var undo_redo: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
			undo_redo.create_action("Add PrimitiveGraphics2D LineDecoration")
			undo_redo.add_do_property(self, &"line_decorations", new_decorations)
			undo_redo.add_undo_property(self, &"line_decorations", line_decorations)
			undo_redo.commit_action()
			),
		["LineDecoration"]
		)


func _tool_remove_line_decoration() -> void:
	var confirmation_dialog: ConfirmationDialog = ConfirmationDialog.new()
	var decoratioins_container: VBoxContainer = VBoxContainer.new()
	
	confirmation_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	confirmation_dialog.title = "Remove LineDecorations"
	
	confirmation_dialog.canceled.connect(_on_remove_line_decoration_cancelled, CONNECT_APPEND_SOURCE_OBJECT)
	confirmation_dialog.confirmed.connect(_on_remove_line_decoration_confirmed, CONNECT_APPEND_SOURCE_OBJECT)
	
	EditorInterface.get_base_control().get_tree().root.add_child(confirmation_dialog)
	confirmation_dialog.add_child(decoratioins_container)
	
	for line_decoration: LineDecoration in line_decorations:
		var check_box: CheckBox = CheckBox.new()
		check_box.text = line_decoration.resource_path.get_file().get_basename()
		check_box.set_meta(&"line_decoration", line_decoration)
		decoratioins_container.add_child(check_box)
	
	confirmation_dialog.size = Vector2.ZERO
	confirmation_dialog.show()


func _on_remove_line_decoration_cancelled(confirmation_dialog: ConfirmationDialog) -> void:
	confirmation_dialog.canceled.disconnect(_on_remove_line_decoration_cancelled)
	confirmation_dialog.confirmed.disconnect(_on_remove_line_decoration_confirmed)
	confirmation_dialog.queue_free()


func _on_remove_line_decoration_confirmed(confirmation_dialog: ConfirmationDialog) -> void:
	confirmation_dialog.canceled.disconnect(_on_remove_line_decoration_cancelled)
	confirmation_dialog.confirmed.disconnect(_on_remove_line_decoration_confirmed)
	
	var decoratioins_container: VBoxContainer = confirmation_dialog.get_child(0)
	var new_decorations: Array[LineDecoration] = line_decorations.duplicate()
	
	for child: Node in decoratioins_container.get_children():
		if child is not CheckBox:
			continue
		var check_box: CheckBox = child
		if not check_box.button_pressed:
			continue
		var line_decoration: LineDecoration = check_box.get_meta(&"line_decoration")
		if new_decorations.has(line_decoration):
			new_decorations.erase(line_decoration)
	
	var undo_redo: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Remove PrimitiveGraphics2D LineDecoration")
	undo_redo.add_do_property(self, &"line_decorations", new_decorations)
	undo_redo.add_undo_property(self, &"line_decorations", line_decorations)
	undo_redo.commit_action()
	
	confirmation_dialog.queue_free()
