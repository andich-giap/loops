class_name PagesTabContainer
extends TabContainer


const PAGE_VIEWPORT: PackedScene = preload("uid://fuajg8iy61yx")
@onready var draw_tool_bar: ToolBar = %DrawToolBar


func set_last_opened_page() -> void:
	if get_child_count() == 0:
		return
	var current_page_viewport: PageViewport = get_current_tab_control() as PageViewport
	if current_page_viewport and current_page_viewport.page_data:
		Global.program_state.last_opened_page = current_page_viewport.page_data
		ResourceSaver.save(Global.program_state)


func open_page(page_data: PageData) -> void:
	if get_child_count() == 0:
		_open_page_in_new_tab(page_data)
		return
	var current_page_viewport: PageViewport = get_current_tab_control() as PageViewport
	current_page_viewport.page_data = page_data
	set_last_opened_page()


func _open_page_in_new_tab(page_data: PageData) -> void:
	var page_viewport: PageViewport = PAGE_VIEWPORT.instantiate()
	page_viewport.page_data = page_data
	add_child(page_viewport)
	set_last_opened_page()


func _on_tool_bar_graphics_added(graphics: Node2D) -> void:
	var current_page_viewport: PageViewport = get_current_tab_control() as PageViewport
	if not current_page_viewport or not current_page_viewport.page_data:
		graphics.queue_free()
		draw_tool_bar.unpress_button()
		return
	current_page_viewport.add_graphics(graphics)


func _set_can_select(can_select: bool) -> void:
	var current_page_viewport: PageViewport = get_current_tab_control() as PageViewport
	current_page_viewport.set_can_select(can_select)


func _on_grid_toggled(toggled_on: bool) -> void:
	Grid.grid_visible = toggled_on
	for child: Node in get_children():
		if child is not PageViewport:
			continue
		var page_viewport: PageViewport = child
		page_viewport.grid.visible = toggled_on


func _on_dxf_inspector_tree_item_selected(source: Tree) -> void:
	var selected_item: TreeItem = source.get_next_selected(null)
	while selected_item:
		var graphics: Node2D
		if selected_item.get_text(0) == "ENTITIES":
			for child: TreeItem in selected_item.get_children():
				child.select(0)
		elif selected_item.get_text(0) == "LINE":
			var poly_line_2d: PolyLine2D = PolyLine2D.new()
			var positions: Array[Vector2]
			positions.resize(2)
			positions.fill(Vector2.ZERO)
			for child: TreeItem in selected_item.get_children():
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
			graphics = poly_line_2d
		if not graphics:
			selected_item = source.get_next_selected(selected_item)
			continue
		var current_page_viewport: PageViewport = get_current_tab_control() as PageViewport
		current_page_viewport.add_graphics(graphics)
		graphics.queue_redraw()
		selected_item = source.get_next_selected(selected_item)
