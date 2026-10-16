@tool
class_name DXFInspector
extends Control


signal file_changed(path: String)
signal add_graphics_requested(graphics: Array[Node])
var file: FileAccess
var tree_root: TreeItem
@onready var tree: Tree = %Tree
@onready var reload_button: Button = $%ReloadButton
@onready var instanciate_button: Button = %InstanciateButton
@onready var open_file_button: Button = %OpenFileButton
@onready var open_file_dialog: FileDialog = %OpenFileDialog


func _ready() -> void:
	if not Engine.is_editor_hint():
		reload_button.queue_free()
	else:
		reload_button.visible = true
	open_file_button.pressed.connect(open_file_dialog.show)
	open_file_dialog.file_selected.connect(_on_open_file_dialog_files_selected)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	instanciate_button.pressed.connect(_on_instanciate_button_pressed)
	file = open("D:/Work_Андич/Новополоцк/СООО ЛЛК-Нафтан/19LUBO/КонтурыСостоянийРСУ.dxf")
	if not file:
		return
	_populate_tree(file)


static func open(file_path: String) -> FileAccess:
	if not FileAccess.file_exists(file_path):
		push_error("Файл не найден: " + file_path)
		return null
	var _file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not _file:
		push_error("Не удалось открыть файл: " + file_path)
		return null
	return _file


static func read(_file: FileAccess) -> Array[String]:
	var extracted_texts: Array[String] = []
	var is_inside_text_entity: bool = false
	while _file.get_position() < _file.get_length():
		var line: String = _file.get_line().strip_edges()
		if line == "0":
			var entity_type: String = _file.get_line().strip_edges()
			if entity_type in ["TEXT", "MTEXT", "AcDbText"]:
				is_inside_text_entity = true
			else:
				is_inside_text_entity = false
		
		if is_inside_text_entity and line == "1":
			var text_value: String = _file.get_line().strip_edges()
			extracted_texts.append(text_value)
			
	_file.close()
	return extracted_texts


static func get_last_saved_by(_file: FileAccess) -> String:
	while _file.get_position() < _file.get_length():
		var line: String = _file.get_line().strip_edges()
		if line == "$LASTSAVEDBY" and _file.get_line().strip_edges() == "1":
			return _file.get_line().strip_edges()
	return ""


static func get_sections(_file: FileAccess) -> Array[String]:
	var sections: Array[String]
	while _file.get_position() < _file.get_length():
		var line: String = _file.get_line().strip_edges()
		if line == "0" and _file.get_line().strip_edges() == "SECTION":
			_file.get_line().strip_edges()
			sections.append(_file.get_line().strip_edges())
	return sections


static func get_header_variables(_file: FileAccess) -> Array[String]:
	var header_variables: Array[String]
	while _file.get_position() < _file.get_length():
		var line: String = _file.get_line().strip_edges()
		if line == "ENDSEC":
			break
		if line == "9":
			var variable_name: String = _file.get_line().strip_edges()
			var variable_value: String = _file.get_line().strip_edges()
			header_variables.append("\t".join([variable_name, variable_value]))
	return header_variables


func _populate_tree(_file: FileAccess) -> void:
	tree.clear()
	tree_root = tree.create_item()
	var section_tree_item: TreeItem
	while _file.get_position() < _file.get_length():
		var line: String = _file.get_line()
		if line == "  0":
			@warning_ignore("unassigned_variable")
			var handle_result: Array = handle_group_code_0(_file, section_tree_item)
			var entity_tree_item: TreeItem = handle_result[0]
			var entity_name: String = handle_result[1]
			if entity_tree_item and entity_name == "SECTION":
				section_tree_item = entity_tree_item
				section_tree_item = entity_tree_item
				var icon: Texture2D
				match section_tree_item.get_text(0):
					"HEADER":
						icon = DXFPlugin.get_editor_icon("Signal")
					"CLASSES":
						icon = DXFPlugin.get_editor_icon("GDScript")
					"TABLES":
						icon = DXFPlugin.get_editor_icon("GridContainer")
					"BLOCKS":
						icon = DXFPlugin.get_editor_icon("PackedScene")
					"ENTITIES":
						icon = DXFPlugin.get_editor_icon("Object")
					"OBJECTS":
						icon = DXFPlugin.get_editor_icon("Curve3D")
					"THUMBNAILIMAGE":
						icon = DXFPlugin.get_editor_icon("Image")
				section_tree_item.set_icon(0, icon)
		if section_tree_item.get_text(0) == "HEADER" and line == "  9":
			_handle_variable(_file, section_tree_item)
		if section_tree_item.get_text(0) == "TABLES":
			_handle_table(_file, section_tree_item)
		if section_tree_item.get_text(0) == "BLOCKS":
			pass
		if section_tree_item.get_text(0) == "ENTITIES":
			_handle_entities(_file, section_tree_item)
	collapse_tree(tree_root)


func collapse_tree(tree_item: TreeItem) -> void:
	for child: TreeItem in tree_item.get_children():
		child.collapsed = true
		collapse_tree(child)


func handle_group_code_0(_file: FileAccess, section_tree_item: TreeItem) -> Array:
	var entity_name: String = _file.get_line().strip_edges()
	var tree_item: TreeItem
	if entity_name == "SECTION":
		_file.get_line()
		var section: String = _file.get_line().strip_edges()
		tree_item = tree_root.create_child()
		tree_item.set_text(0, section)
	elif entity_name == "CLASS":
		_file.get_line()
		tree_item = section_tree_item.create_child()
		var class_string_name: String = _file.get_line().strip_edges()
		tree_item.set_text(0, class_string_name)
	return [tree_item, entity_name]


func _handle_variable(_file: FileAccess, parent_tree_item: TreeItem) -> void:
	var variable_name: String = _file.get_line().strip_edges()
	var variable_type: int = int(_file.get_line().strip_edges())
	var variable_value: String = _file.get_line().strip_edges()
	var variable_tree_item: TreeItem = parent_tree_item.create_child()
	var variable_texture: Texture2D
	
	if variable_type >= 1 and variable_type <= 8:
		variable_texture = DXFPlugin.get_editor_icon("String")
	
	if variable_type >= 70 and variable_type <= 78 or variable_type in [290, 380]:
		variable_texture = DXFPlugin.get_editor_icon("bool")
	
	if variable_type in [90, 160, 280]:
		variable_texture = DXFPlugin.get_editor_icon("int")
	
	if variable_type >= 40 and variable_type <= 48 or variable_type in [370]:
		variable_texture = DXFPlugin.get_editor_icon("float")
	
	if variable_type >= 10 and variable_type <= 18:
		variable_texture = DXFPlugin.get_editor_icon("Vector3")
		_file.get_line().strip_edges()
		variable_value += ", " + _file.get_line().strip_edges()
		_file.get_line().strip_edges()
		variable_value += ", " + _file.get_line().strip_edges()
	
	if variable_type == 347:
		variable_texture = DXFPlugin.get_editor_icon("ShaderMaterial")
	
	if variable_type >= 50 and variable_type <= 58:
		variable_texture = DXFPlugin.get_editor_icon("Quaternion")
	
	if variable_type == 62:
		variable_texture = DXFPlugin.get_editor_icon("Color")
	
	variable_tree_item.set_text(0, "   ".join([variable_name, variable_value]))
	variable_tree_item.set_icon(0, variable_texture)


func _handle_table(_file: FileAccess, section_tree_item: TreeItem) -> void:
	var line: String = _file.get_line()
	var entity_type: String = line
	var entity_name: String = _file.get_line().strip_edges()
	var table_name: String 
	var table_tree_item: TreeItem
	if entity_type == "  0" and entity_name == "TABLE":
		_file.get_line()
		table_name = _file.get_line().strip_edges()
		table_tree_item = section_tree_item.create_child()
		table_tree_item.set_text(0, table_name)
	else:
		return
	line = _file.get_line()
	while not line == "ENDTAB":
		var variable_name: String = line
		var variable_value: String = _file.get_line().strip_edges()
		if variable_value.begins_with("{"):
			while not variable_value.ends_with("}"):
				variable_value += _file.get_line().strip_edges()
		if variable_name == "  0" and variable_value == table_name:
			var sub_entity_tree_item: TreeItem = table_tree_item.create_child()
			sub_entity_tree_item.set_text(0, variable_value)
			line = _file.get_line()
			while not line == "  0":
				variable_name = line.strip_edges()
				variable_value = _file.get_line().strip_edges()
				if variable_value.begins_with("{"):
					while not variable_value.ends_with("}"):
						variable_value += _file.get_line().strip_edges()
				var variable_tree_item: TreeItem = sub_entity_tree_item.create_child()
				variable_tree_item.set_text(0, variable_name + " " + variable_value)
				if variable_name == "2":
					sub_entity_tree_item.set_text(0, variable_value)
				line = _file.get_line()
			continue
		elif line == "  0" and variable_value == "ENDTAB":
			break
		else:
			var variable_tree_item: TreeItem = table_tree_item.create_child()
			variable_tree_item.set_text(0, variable_name.strip_edges() + " " + variable_value)
		line = _file.get_line()
	_handle_table(_file, section_tree_item)


func _handle_entities(_file: FileAccess, section_tree_item: TreeItem) -> void:
	var line: String = _file.get_line()
	while not line == "ENDSEC":
		var variable_name: String = line
		var variable_value: String = _file.get_line().strip_edges()
		var variable_tree_item: TreeItem
		if variable_value == "ENDSEC":
			return
		if variable_value.begins_with("{"):
			while not variable_value.ends_with("}"):
				variable_value += _file.get_line().strip_edges()
		if variable_name == "  0":
			var entity_tree_item: TreeItem = section_tree_item.create_child()
			entity_tree_item.set_text(0, variable_value)
			var icon: Texture2D
			match variable_value:
				"LINE":
					icon = DXFPlugin.get_editor_icon("Line2D")
				"TEXT":
					icon = DXFPlugin.get_editor_icon("TextMesh")
				"VIEWPORT":
					icon = DXFPlugin.get_editor_icon("Viewport")
				"_":
					pass
			if icon:
				entity_tree_item.set_icon(0, icon)
			line = _file.get_line()
			while not line == "  0":
				variable_name = line
				variable_value = _file.get_line().strip_edges()
				if variable_value.begins_with("{"):
					while not variable_value.ends_with("}"):
						variable_value += _file.get_line().strip_edges()
				variable_tree_item = entity_tree_item.create_child()
				variable_tree_item.set_text(0, variable_name.strip_edges() + " " + variable_value)
				line = _file.get_line()
			continue
		variable_tree_item = section_tree_item.create_child()
		variable_tree_item.set_text(0, variable_name.strip_edges() + " " + variable_value)
		line = _file.get_line()


func _on_instanciate_button_pressed() -> void:
	var root_children: Array[TreeItem] = tree.get_root().get_children()
	var entities_item: TreeItem
	for child: TreeItem in root_children:
		if child.get_text(0) == "ENTITIES":
			entities_item = child
			break
	var graphics: Array[Node]
	for entity: TreeItem in entities_item.get_children():
		if entity.get_text(0) == "MTEXT":
			graphics.append(_dxf_get_l_line_edit_from_tree_item(entity))
		elif entity.get_text(0) == "LINE":
			graphics.append(_dxf_get_poly_line_2d_from_tree_item(entity))
	if graphics.is_empty():
		return
	add_graphics_requested.emit(graphics)


func _dxf_get_poly_line_2d_from_tree_item(tree_item: TreeItem) -> PolyLine2D:
	var poly_line_2d: PolyLine2D = PolyLine2D.new()
	var positions: Array[Vector2]
	positions.resize(2)
	positions.fill(Vector2.ZERO)
	poly_line_2d.width = 0.25
	for child: TreeItem in tree_item.get_children():
		var variable_name: String = child.get_text(0).split(" ")[0]
		var variable_value: String = child.get_text(0).split(" ")[1]
		match variable_name:
			"10":
				positions[0] += Vector2(float(variable_value), 0.0)
			"20":
				positions[0] -= Vector2(0.0, float(variable_value))
			"11":
				positions[1] += Vector2(float(variable_value), 0.0)
			"21":
				positions[1] -= Vector2(0.0, float(variable_value))
	for point_position: Vector2 in positions:
		poly_line_2d.add_point(point_position)
	poly_line_2d.update_bounding_box()
	return poly_line_2d


func _dxf_get_l_line_edit_from_tree_item(tree_item: TreeItem) -> LLineEdit:
	var l_line_edit: LLineEdit = LLineEdit.new()
	for child: TreeItem in tree_item.get_children():
		var child_text: PackedStringArray = child.get_text(0).split(" ")
		var variable_name: String = child_text[0]
		child_text.remove_at(0)
		var variable_value: String = " ".join(child_text)
		match variable_name:
			"1":
				var string_components: PackedStringArray = variable_value.split("\\")
				var text: String = string_components[-1].erase(0, 1)
				l_line_edit.text = text
			"10":
				l_line_edit.position.x = float(variable_value)
			"20":
				l_line_edit.position.y = - float(variable_value)
			"40":
				l_line_edit.set_font_size(int(Units.mm_to_px(float(variable_value)/2)))
	return l_line_edit


func _on_open_file_dialog_files_selected(path: String) -> void:
	file = open(path)
	file_changed.emit(path)
	_populate_tree(file)
