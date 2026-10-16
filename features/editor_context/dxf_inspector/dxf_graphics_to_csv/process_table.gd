extends Control


@export var page_viewport: PageViewport
var cells: Dictionary[int, Dictionary] ## Basically 2 dim array.
var loops: Dictionary[StringName, Dictionary]
var horizontal_poly_lines: Array[PolyLine2D]
var vertical_poly_lines: Array[PolyLine2D]
var l_line_edits: Array[LLineEdit]
var file_path: String
var dxf_inspector: DXFInspector


func _ready() -> void:
	dxf_inspector = get_tree().get_first_node_in_group(&"dxf_inspector")
	dxf_inspector.file_changed.connect(_on_dxf_inspector_file_changed)


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_2) and Input.is_key_pressed(KEY_ALT):
		trigger_process(false)
	if Input.is_key_pressed(KEY_4) and Input.is_key_pressed(KEY_ALT):
		trigger_process(true)


func get_active_file_path() -> String:
	return dxf_inspector.file.get_path().get_base_dir() + "/Process/" + page_viewport.page_data.description + ".dxf"


func trigger_process(process_status: bool) -> void:
		file_path = get_active_file_path()
		var file_name: String = file_path.get_file().get_basename()
		process_table()
		var data: String = process_loops()
		if process_status:
			data = process_csv_data(data)
			save_string("%s/%s.csv" % [file_path.get_base_dir(), file_name], data)
			var lines: PackedStringArray = data.split("\n")
			var status_data_dictionary: Dictionary[String, Dictionary] = parse_status_data(lines)
			data = get_nested_json(status_data_dictionary)
			#save_string("%s/%s.json" % [file_path.get_base_dir(), file_name], data)
			parse_status_data_json_to_csv(data, "%s/%s.csv" % [file_path.get_base_dir(), file_name])
		else:
			data = parse_control_data()
			save_string("%s/%s.csv" % [file_path.get_base_dir(), file_name], data)
		queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.is_released():
			print(check_cell(get_local_mouse_position()), "_")


func _draw() -> void:
	if not cells:
		return
	for i: int in cells.keys():
		for k: int in cells[i].keys():
			var cell: Cell = cells[i][k]
			draw_rect(cell.rect, Color.from_hsv(get_normalized_hash(cell), 1.0, 1.0, 0.3))
			draw_string(
				get_theme_default_font(),
				cell.rect.get_center() + Vector2(0.0, 2),
				" ".join([i,k]),
				HORIZONTAL_ALIGNMENT_CENTER,
				-1,
				4,
				Color.BLACK
			)
	for l_line_edit: LLineEdit in l_line_edits:
		if l_line_edit.visible:
			draw_circle(l_line_edit.position, 0.25, Color.RED)
			draw_rect(l_line_edit.get_rect(), Color.BLACK, false, 0.25)


func process_table() -> void:
	page_viewport._set_can_select(false)
	cells.clear()
	loops.clear()
	horizontal_poly_lines.clear()
	vertical_poly_lines.clear()
	l_line_edits.clear()
	
	for node: Node in page_viewport.contents_layer.get_children():
		if node is PolyLine2D:
			var poly_line: PolyLine2D = node
			if is_equal_approx(poly_line.points[0].x, poly_line.points[1].x):
				vertical_poly_lines.append(poly_line)
			else:
				horizontal_poly_lines.append(poly_line)
		elif node is LLineEdit:
			var l_line_edit: LLineEdit = node
			l_line_edit.size = Vector2.ZERO
			l_line_edits.append(l_line_edit)
			
	
	horizontal_poly_lines.sort_custom(sort_poly_lines.bind(true))
	vertical_poly_lines.sort_custom(sort_poly_lines.bind(false))
	
	if vertical_poly_lines.size() > 0 and horizontal_poly_lines.size() > 0:
		size = Vector2(
			vertical_poly_lines[-1].points[0].x,
			absf(horizontal_poly_lines[-1].points[0].y)
		)
	
	var epsilon: float = 1.0 
	
	for hpl: int in range(horizontal_poly_lines.size()):
		var h_line: PolyLine2D = horizontal_poly_lines[hpl]
		
		for vpl: int in range(vertical_poly_lines.size() - 1):
			var v_line: PolyLine2D = vertical_poly_lines[vpl]
			var next_v_line: PolyLine2D = vertical_poly_lines[vpl + 1]
			
			var cell_left: float = v_line.points[0].x
			var cell_right: float = next_v_line.points[0].x
			var cell_top: float = h_line.points[0].y
			
			var h_min_x: float = minf(h_line.points[0].x, h_line.points[1].x)
			var h_max_x: float = maxf(h_line.points[0].x, h_line.points[1].x)
			
			if h_min_x > cell_left + epsilon or h_max_x < cell_right - epsilon:
				continue 
				
			var cell_bottom: float = _get_next_line_position_y_for_column(
				cell_top, 
				cell_left, 
				cell_right, 
				horizontal_poly_lines,
				hpl
			)
			
			if is_equal_approx(cell_bottom, 0.0) or cell_bottom <= cell_top + epsilon:
				continue
				
			var is_duplicate: bool = false
			if cells.has(vpl):
				for existing_hpl: int in cells[vpl]:
					var cell_rect: Rect2 = cells[vpl][existing_hpl].rect
					if cell_top > cell_rect.position.y + epsilon and cell_top < cell_rect.position.y + cell_rect.size.y - epsilon:
						is_duplicate = true
						break
			
			if is_duplicate:
				continue
			
			var cell: Cell = Cell.new()
			cell.rect = Rect2()
			cell.rect.position = Vector2(cell_left, cell_top)
			cell.rect.size = Vector2(cell_right - cell_left, cell_bottom - cell_top)
			cell.x = vpl
			cell.y = hpl
			
			if not cells.has(vpl):
				cells[vpl] = {}
			cells[vpl][hpl] = cell
	
	for l_line_edit: LLineEdit in l_line_edits:
		for i: int in cells.keys():
			for k: int in cells[i].keys():
				var cell: Cell = cells[i][k]
				if cell.rect.has_point(l_line_edit.position):
					cell.content.append(l_line_edit)


func process_loops() -> String:
	loops.clear()
	
	var row_indices: Array[int] = []
	for col: Dictionary in cells.values():
		for row_idx: int in col.keys():
			if not row_indices.has(row_idx):
				row_indices.append(row_idx)
	row_indices.sort()
	
	var max_cols: int = 0
	for col_idx: int in cells.keys():
		max_cols = max(max_cols, col_idx + 1)
		
	if max_cols == 0 or row_indices.is_empty():
		return ""

	var csv_lines: PackedStringArray = PackedStringArray()

	for row_idx: int in row_indices:
		var csv_row_tokens: PackedStringArray = PackedStringArray()
		
		for col_idx: int in range(max_cols):
			if cells.has(col_idx) and cells[col_idx].has(row_idx):
				var cell: Cell = cells[col_idx][row_idx]
				
				var text: String = cell.get_content_text().strip_edges()
				text = text.replace('"', '""') 
				csv_row_tokens.append('"' + text + '"')
			else:
				csv_row_tokens.append('""')
				
		csv_lines.append(",".join(csv_row_tokens))
		
	var csv_output: String = "\n".join(csv_lines)
	return csv_output


func process_csv_data(csv: String) -> String:
	var processed: String
	var rows: PackedStringArray = csv.split("\n")
	var skip_count: int = 0
	for row: int in range(rows.size()):
		for skip: int in range(skip_count):
			continue
		if not row == 0:
			processed = processed + "\n"
		var columns: PackedStringArray = rows[row].split(",")
		for column: int in range(columns.size()):
			processed = processed + ","
			var value: String = columns[column]
			processed = processed + value
	return processed


## Utility helper to export the generated CSV string directly onto your disk
func save_string(path: String, string: String) -> void:
	if string == "":
		push_warning("Cannot export empty table grid data to CSV.")
		return
		
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(string)
		file.close()
		print("Table successfully exported to CSV: ", path)
	else:
		push_error("Failed to open or write file at target path: ", path, FileAccess.get_open_error())


func parse_status_data(csv_rows: Array, skip_headers_count: int = 2) -> Dictionary[String, Dictionary]:
	var result: Dictionary[String, Dictionary] = {}
	
	if csv_rows.size() <= skip_headers_count:
		return result
		
	var current_parent_key: String = ""
	var current_type: String = "События"
	
	for i: int in range(skip_headers_count, csv_rows.size()):
		var raw_row: Variant = csv_rows[i]
		if raw_row == null:
			continue
			
		var row: PackedStringArray = _normalize_row(raw_row)
		if row.size() < 3:
			continue
			
		var primary_cell: String = _clean_cell(row[1])
		if not primary_cell.is_empty():
			current_parent_key = primary_cell
			if not result.has(current_parent_key):
				var typed_dict: Dictionary[String, Array] = {
					"Причины": [] as Array[PackedStringArray],
					"События": [] as Array[PackedStringArray]
				}
				result[current_parent_key] = typed_dict
		
		if current_parent_key.is_empty():
			continue
			
		var row_type: String = _clean_cell(row[2])
		if row_type == "Причины" or row_type == "События":
			current_type = row_type
		
		var child_data: PackedStringArray = row.slice(3)
		for cell_idx: int in range(child_data.size()):
			child_data[cell_idx] = _clean_cell(child_data[cell_idx])
		var category_data: Array[PackedStringArray] = result[current_parent_key][current_type]
		category_data.append(child_data)
	return result


func parse_control_data() -> String:
	# 1. Gather all unique X and Y coordinates to find the grid boundaries
	var x_coords: Array = cells.keys()
	var y_coords: Array = []
	
	for x: int in x_coords:
		for y: int in cells[x].keys():
			if not y in y_coords:
				y_coords.append(y)
	
	# Sort them to ensure they process in correct numerical order (0, 1, 2...)
	x_coords.sort()
	y_coords.sort()
	
	# 2. Build rows by iterating Y (rows) first, then X (columns)
	var rows: Array = []
	for y: int in y_coords:
		var row_cells: Array = []
		for x: int in x_coords:
			# Safety check in case a specific cell coordinate is missing
			if cells.has(x) and cells[x].has(y):
				var cell: Cell = cells[x][y]
				row_cells.append(cell.get_content_text())
			else:
				row_cells.append("") # Empty cell if missing
		
		# Join columns with a comma
		rows.append(",".join(row_cells))
	
	# 3. Join all rows with a newline
	return "\n".join(rows)


func parse_status_data_json_to_csv(json: String, path: String) -> void:
	var data: Dictionary = JSON.parse_string(json)
	var csv_data: PackedStringArray
	var row: PackedStringArray
	for loop: String in data.keys():
		row.clear()
		row.append(loop)
		var loop_data: Dictionary = data[loop]
		for cause_action_key: String in loop_data.keys():
			row.append(cause_action_key)
			var cause_action_values: PackedStringArray
			for cause_action_data: Array in data[loop][cause_action_key]:
				cause_action_values.append(str(cause_action_data[4] + ":" + cause_action_data[3]))
			row.append("|".join(cause_action_values))
		var row_string: String = ",".join(row)
		csv_data.append(row_string)
	var csv: String = "\n".join(csv_data)
	save_string(path.get_basename() + ".csv", csv)


## Вспомогательный метод для приведения строки к PackedStringArray
func _normalize_row(raw_row: Variant) -> PackedStringArray:
	if raw_row is String:
		var clean_string: String = raw_row
		clean_string = clean_string.strip_edges()
		return PackedStringArray() if clean_string.is_empty() else clean_string.split(",")
		
	if raw_row is Array or raw_row is PackedStringArray:
		var row: PackedStringArray = PackedStringArray()
		for cell: Variant in raw_row:
			row.append(str(cell))
		return row
		
	return PackedStringArray()


## Вспомогательный метод для очистки ячеек от пробелов и кавычек
func _clean_cell(cell: String) -> String:
	return cell.strip_edges().replace('"', '').replace("'", "")


# Helper function to easily convert the generated dictionary to a clean JSON string
func get_nested_json(data: Dictionary) -> String:
	return JSON.stringify(data, "\t")


func _get_next_line_position_y_for_column(current_y: float, col_left: float, col_right: float, lines: Array[PolyLine2D], start_index: int) -> float:
	var epsilon: float = 1.0
	for i: int in range(start_index + 1, lines.size()):
		var candidate: PolyLine2D = lines[i]
		
		if candidate.points[0].y <= current_y + epsilon:
			continue
			
		var cand_min_x: float = minf(candidate.points[0].x, candidate.points[1].x)
		var cand_max_x: float = maxf(candidate.points[0].x, candidate.points[1].x)
		
		var covers_column: bool = cand_min_x <= col_left + epsilon and cand_max_x >= col_right - epsilon
		if covers_column:
			return candidate.points[0].y
	return 0.0


func sort_poly_lines(line_1: PolyLine2D, line_2: PolyLine2D, is_horizontal: bool) -> bool:
	var position_1: float
	var position_2: float
	if is_horizontal:
		position_1 = line_1.points[0].y
		position_2 = line_2.points[0].y
	else:
		position_1 = line_1.points[0].x
		position_2 = line_2.points[0].x
	return position_1 < position_2


func get_normalized_hash(input_value: Variant) -> float:
	return float(hash(input_value)) / 4294967295.0


func _on_dxf_inspector_file_changed(path: String) -> void:
	file_path = path


func check_cell(pos: Vector2) -> String:
	if not cells:
		return ""
	for i: int in cells.keys():
		for k: int in cells[i].keys():
			var cell: Cell = cells[i][k]
			if cell.rect.has_point(pos):
				return cell.get_content_text()
	return ""


class Cell:
	var x: int
	var y: int
	var rect: Rect2
	var content: Array[LLineEdit]
	var content_text: String:
		get = get_content_text
	
	func get_content_text() -> String:
		var line: PackedStringArray = PackedStringArray()
		for l_line_edit: LLineEdit in content:
			line.append(l_line_edit.text)
		return " ".join(line)
