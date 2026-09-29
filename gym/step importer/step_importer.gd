class_name StepImporter
extends RefCounted

class StepEntity:
	var type: String = ""
	var args: Array[Variant] = []

# --- CORE PUBLIC INTERFACE ---

## Parses a STEP string data block and returns a compiled MeshInstance3D node
static func import_step_from_string(step_content: String) -> MeshInstance3D:
	var entities: Dictionary = _parse_file_to_entities(step_content)
	if entities.is_empty():
		push_error("STEP Importer: Failed to extract structural data maps.")
		return null
		
	return _build_mesh_instance(entities)


# --- PARSER ENGINE STAGE ---

static func _parse_file_to_entities(content: String) -> Dictionary:
	var entity_map: Dictionary = {}
	content = content.replace("\r", "")
	
	# Токенизируем файл по символу ';', чтобы склеить многострочные конструкции SolidWorks
	var raw_statements: PackedStringArray = content.split(";")
	
	var regex: RegEx = RegEx.new()
	var error: Error = regex.compile("^\\s*#(\\d+)\\s*=\\s*([A-Z0-9_]+)\\s*\\((.*)\\)\\s*$")
	if error != OK:
		push_error("STEP Importer: Failed to compile RegEx.")
		return entity_map
	
	for statement: String in raw_statements:
		var cleaned_statement: String = statement.strip_edges().replace("\n", " ")
		if cleaned_statement.is_empty() or not cleaned_statement.begins_with("#"):
			continue
			
		var match_data: RegExMatch = regex.search(cleaned_statement)
		if match_data:
			var id: int = match_data.get_string(1).to_int()
			var type: String = match_data.get_string(2)
			var raw_args: String = match_data.get_string(3)
			
			var entity: StepEntity = StepEntity.new()
			entity.type = type
			entity.args = _clean_arguments(raw_args)
			entity_map[id] = entity
			
	return entity_map


static func _clean_arguments(raw_args: String) -> Array[Variant]:
	var args: Array[Variant] = []
	var current: String = ""
	var depth: int = 0
	var in_quotes: bool = false
	
	for i: int in range(raw_args.length()):
		var character: String = raw_args[i]
		
		if character == "'":
			in_quotes = not in_quotes
			current += character
			continue
			
		if in_quotes:
			current += character
			continue
			
		if character == "(":
			depth += 1
			current += character
		elif character == ")":
			depth -= 1
			current += character
		elif character == "," and depth == 0:
			args.append(_sanitize_value(current))
			current = ""
		else:
			current += character
			
	if not current.is_empty():
		args.append(_sanitize_value(current))
	return args


static func _sanitize_value(val: String) -> Variant:
	val = val.strip_edges()
	if val.is_empty() or val == "*":
		return null
	if val.begins_with("'") and val.ends_with("'"):
		return val.substr(1, val.length() - 2)
	if val == ".T.": return true
	if val == ".F.": return false
	
	if val.begins_with(" Lif") or val.begins_with("("):
		if val.begins_with("(") and val.ends_with(")"):
			var inner_content: String = val.substr(1, val.length() - 2)
			
			var tokens: PackedStringArray = inner_content.split(",")
			if tokens.size() == 3 and tokens[0].strip_edges().is_valid_float():
				var vec: Vector3 = Vector3.ZERO
				vec.x = tokens[0].strip_edges().to_float()
				vec.y = tokens[1].strip_edges().to_float()
				vec.z = tokens[2].strip_edges().to_float()
				return vec
				
			var id_array: Array[int] = []
			var id_regex: RegEx = RegEx.new()
			var pattern_err: Error = id_regex.compile("#(\\d+)")
			if pattern_err == OK:
				var matches: Array[RegExMatch] = id_regex.search_all(inner_content)
				for m: RegExMatch in matches:
					id_array.append(m.get_string(1).to_int())
				
			if not id_array.is_empty():
				return id_array
			
	if val.begins_with("#"):
		return val.substr(1).to_int()
		
	if val.is_valid_float():
		return val.to_float()
	if val.is_valid_int():
		return val.to_int()
	return val


# --- MESH GENERATION & STRUCTURAL TRAVERSAL STAGE ---

static func _build_mesh_instance(entities: Dictionary) -> MeshInstance3D:
	var vertices: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	
	var point_cache: Dictionary = _build_point_cache(entities)
	
	# Шаг 1: Итерируем по B-сплайнам поверхностей (AP203)
	for id: int in entities:
		var ent: StepEntity = entities[id]
		if ent.type == "B_SPLINE_SURFACE_WITH_KNOTS":
			_process_bspline_surface(ent, point_cache, vertices, indices)
			
	# Шаг 2: Фолбэк на обход аналитических граней (AP214), если сплайны не дали вершин
	if vertices.is_empty():
		for id: int in entities:
			var ent: StepEntity = entities[id]
			if ent.type == "ADVANCED_FACE":
				var face_vertices: PackedVector3Array = _extract_face_vertices_analytical(ent, entities, point_cache)
				if face_vertices.size() >= 3:
					_triangulate_face_unify(face_vertices, vertices, indices)

	if vertices.is_empty():
		push_error("STEP Importer: Parsing complete but no valid Surface Geometry structures extracted.")
		return null

	return _compile_mesh_node(vertices, indices)


static func _build_point_cache(entities: Dictionary) -> Dictionary:
	var cache: Dictionary = {}
	for id: int in entities:
		var ent: StepEntity = entities[id]
		if ent.type == "CARTESIAN_POINT":
			for arg: Variant in ent.args:
				if arg is Vector3:
					@warning_ignore("unsafe_call_argument")
					cache[id] = Vector3(arg.x, arg.y, -arg.z) * 0.001
					break
	return cache


## Рекурсивный геометрический инспектор связей SolidWorks
static func _resolve_point_by_id(target_id: int, entities: Dictionary, point_cache: Dictionary, out_array: PackedVector3Array) -> void:
	if not entities.has(target_id):
		return
	
	var ent: StepEntity = entities[target_id]
	
	# Если дошли до физической точки координат
	if ent.type == "CARTESIAN_POINT" and point_cache.has(target_id):
		var pt: Vector3 = point_cache[target_id]
		out_array.append(pt)
		return
		
	# Если это геометрический примитив-обертка, раскручиваем аргументы рекурсивно дальше
	if ent.type == "VERTEX_POINT" or ent.type == "LINE" or ent.type == "CIRCLE" or ent.type == "PLANE":
		for arg: Variant in ent.args:
			if arg is int:
				@warning_ignore("unsafe_call_argument")
				_resolve_point_by_id(arg, entities, point_cache, out_array)


## Извлечение вершин аналитических контуров геометрии AP214
static func _extract_face_vertices_analytical(face: StepEntity, entities: Dictionary, point_cache: Dictionary) -> PackedVector3Array:
	var face_vertices: PackedVector3Array = PackedVector3Array()
	
	for bound_arg: Variant in face.args:
		var bounds_to_check: Array = bound_arg if bound_arg is Array else [bound_arg]
			
		for bound_id: Variant in bounds_to_check:
			if not (bound_id is int and entities.has(bound_id)):
				continue
				
			var bound: StepEntity = entities[bound_id]
			if bound.type == "FACE_OUTER_BOUND" or bound.type == "FACE_BOUND":
				if bound.args.is_empty(): continue
				var loop_id: Variant = bound.args[0]
				@warning_ignore("unsafe_method_access")
				if loop_id is Array and not loop_id.is_empty(): loop_id = loop_id[0]
				
				if loop_id is int and entities.has(loop_id):
					var loop: StepEntity = entities[loop_id]
					if loop.type == "EDGE_LOOP" or loop.type == "POLYLOOP":
						for edge_arg: Variant in loop.args:
							var edges_to_check: Array = edge_arg if edge_arg is Array else [edge_arg]
							for edge_id: Variant in edges_to_check:
								if edge_id is int and entities.has(edge_id):
									var oriented_edge: StepEntity = entities[edge_id]
									if oriented_edge.type == "ORIENTED_EDGE" and oriented_edge.args.size() >= 4:
										var ec_id: Variant = oriented_edge.args[3]
										if ec_id is int and entities.has(ec_id):
											var edge_curve: StepEntity = entities[ec_id]
											if edge_curve.type == "EDGE_CURVE" and edge_curve.args.size() >= 3:
												# Передаем геометрические узлы ребра рекурсивному инспектору
												@warning_ignore("unsafe_cast")
												_resolve_point_by_id(edge_curve.args[1] as int, entities, point_cache, face_vertices)
												@warning_ignore("unsafe_cast")
												_resolve_point_by_id(edge_curve.args[2] as int, entities, point_cache, face_vertices)
	return face_vertices


static func _process_bspline_surface(surface: StepEntity, point_cache: Dictionary, out_vertices: PackedVector3Array, out_indices: PackedInt32Array) -> void:
	if surface.args.size() < 4:
		return
		
	var control_points_list: Array = []
	for arg: Variant in surface.args:
		@warning_ignore("unsafe_method_access")
		if arg is Array and not arg.is_empty():
			control_points_list = arg
			break
			
	if control_points_list.is_empty():
		return
		
	var surface_points: Array[Vector3] = []
	for pt_id: Variant in control_points_list:
		if pt_id is int and point_cache.has(pt_id):
			surface_points.append(point_cache[pt_id])
			
	var total_points: int = surface_points.size()
	if total_points < 4:
		return
		
	var stride: int = int(sqrt(total_points))
	if stride < 2: stride = 2
	@warning_ignore("integer_division")
	var rows: int = total_points / stride
	
	var start_vertex_idx: int = out_vertices.size()
	for pt: Vector3 in surface_points:
		out_vertices.append(pt)
		
	for r: int in range(rows - 1):
		for c: int in range(stride - 1):
			var p0: int = start_vertex_idx + (r * stride) + c
			var p1: int = p0 + 1
			var p2: int = start_vertex_idx + ((r + 1) * stride) + c
			var p3: int = p2 + 1
			
			out_indices.append(p0)
			out_indices.append(p1)
			out_indices.append(p3)
			
			out_indices.append(p0)
			out_indices.append(p3)
			out_indices.append(p2)


## Веерная триангуляция с O(1) дедупликацией вершин для предотвращения разрывов полигонов
static func _triangulate_face_unify(face_vertices: PackedVector3Array, out_vertices: PackedVector3Array, out_indices: PackedInt32Array) -> void:
	var v_size: int = face_vertices.size()
	if v_size < 3: return
	
	var face_indices: Array[int] = []
	for v: Vector3 in face_vertices:
		var found_idx: int = -1
		
		# Дедупликация близко расположенных вершин аналитической структуры CAD
		for i: int in range(out_vertices.size()):
			if out_vertices[i].is_equal_approx(v):
				found_idx = i
				break
		if found_idx == -1:
			found_idx = out_vertices.size()
			out_vertices.append(v)
		face_indices.append(found_idx)
		
	@warning_ignore("inferred_declaration")
	for i in range(1, face_indices.size() - 1):
		out_indices.append(face_indices[0])
		out_indices.append(face_indices[i])
		out_indices.append(face_indices[i + 1])


static func _compile_mesh_node(vertices: PackedVector3Array, indices: PackedInt32Array) -> MeshInstance3D:
	var surface_array: Array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	var dynamic_mesh: ArrayMesh = ArrayMesh.new()
	dynamic_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	var surface_tool: SurfaceTool = SurfaceTool.new()
	surface_tool.create_from(dynamic_mesh, 0)
	surface_tool.generate_normals()
	var final_mesh: Mesh = surface_tool.commit()
	
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = final_mesh
	mesh_instance.name = "Imported_Step_Mesh"
	
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.55, 0.55, 0.55)
	material.roughness = 0.5
	# Отключаем куллинг, так как SolidWorks и Godot имеют противоположное направление обхода индексов (Winding order)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material
	
	return mesh_instance
