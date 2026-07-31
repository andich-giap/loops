class_name LLineEdit
extends LineEdit


var is_selected: bool = false:
	set = set_is_selected


func add_to_selection() -> void:
	is_selected = true
	queue_redraw()


func remove_from_selection() -> void:
	is_selected = false
	queue_redraw()


func get_editable_properties() -> Array[Dictionary]:
	var editable_properties_names: Array[StringName] = [
		&"text",
		&"alignment",
	]
	var editable_properties: Array[Dictionary]
	for property: Dictionary in get_property_list():
		if not editable_properties_names.has(property["name"]):
			continue
		editable_properties.append(property)
	return editable_properties


func set_is_selected(_is_selected: bool) -> void:
	is_selected = _is_selected
	#if is_selected:
		#default_color = ProjectColor.selection_values[ProjectColor.Selection.LINE]
		#if gizmos.is_empty():
			#_add_gizmos()
		#for point: int in range(points.size()):
			#var gizmo: Gizmo = gizmos[point]
			#var gizmo_position: Vector2 = get_point_position(point)
			#var gizmo_grab_size: Vector2 = Vector2(Units.mm_to_px(gizmo.radius), Units.mm_to_px(gizmo.radius)) / 1.5
			#gizmo.set_begin(gizmo_position - gizmo_grab_size)
			#gizmo.set_end(gizmo_position + gizmo_grab_size)
			#gizmo.position_changed.connect(_on_gizmo_position_changed.bind(point))
			#gizmo.grabbed.connect(_on_gizmo_grabbed.bind(point))
			#gizmo.released.connect(_on_gizmo_released)
	#else:
		#default_color = color
		#if not gizmos.is_empty():
			#_remove_gizmos()
	queue_redraw()
