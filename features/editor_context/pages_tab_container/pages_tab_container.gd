class_name PagesTabContainer
extends TabContainer
## Contains opened pages as [PageViewport]s.


const PAGE_VIEWPORT: PackedScene = preload("uid://fuajg8iy61yx")
var current_page: PageViewport: ## Returns focused [PageViewport] or [code]null[/code] if there are no pages opened.
	get = get_current_page


func _init() -> void:
	name = "PagesTabContainer"


## Opens the page as a [PageViewport]. Replaces the contents of currently active [PageViewport].
func open_page(page_data: PageData) -> void:
	if get_child_count() == 0:
		open_page_in_new_tab(page_data)
		return
	var current_page_viewport: PageViewport = get_current_tab_control() as PageViewport
	current_page_viewport.page_data = page_data


## Opens the page as a [PageViewport].
func open_page_in_new_tab(page_data: PageData) -> void:
	var page_viewport: PageViewport = PAGE_VIEWPORT.instantiate()
	page_viewport.page_data = page_data
	add_child(page_viewport)


func get_current_page() -> PageViewport:
	if get_child_count() == 0:
		return null
	var tab: Control = get_current_tab_control()
	if tab is PageViewport:
		return tab
	return null


func _on_tool_bar_graphics_added(graphics: Node) -> void:
	var current_page_viewport: PageViewport = get_current_tab_control() as PageViewport
	if not current_page_viewport or not current_page_viewport.page_data:
		graphics.queue_free()
		#draw_tool_bar.unpress_button()
		return
	current_page_viewport.add_graphics(graphics)


func _on_grid_toggled(toggled_on: bool) -> void:
	for child: Node in get_children():
		if child is not PageViewport:
			continue
		var page_viewport: PageViewport = child
		page_viewport.grid.visible = toggled_on


func _on_dxf_inspector_tree_item_selected(source: Tree) -> void:
	var selected_item: TreeItem = source.get_next_selected(null)
	while selected_item:
		var graphics: Node
		match selected_item.get_text(0):
			"ENTITIES":
				for child: TreeItem in selected_item.get_children():
					child.select(0)
			"LINE":
				graphics = _dxf_get_poly_line_2d_from_tree_item(selected_item)
			"TEXT":
				graphics = _dxf_get_l_line_edit_from_tree_item(selected_item)
		if not graphics:
			selected_item = source.get_next_selected(selected_item)
			continue
		current_page.add_graphics(graphics)
		if graphics.has_method("queue_redraw"):
			graphics.call("queue_redraw")
		selected_item = source.get_next_selected(selected_item)


func _dxf_get_poly_line_2d_from_tree_item(tree_item: TreeItem) -> PolyLine2D:
	var poly_line_2d: PolyLine2D = PolyLine2D.new()
	var positions: Array[Vector2]
	positions.resize(2)
	positions.fill(Vector2.ZERO)
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
		var variable_name: String = child.get_text(0).split(" ")[0]
		var variable_value: String = child.get_text(0).split(" ")[1]
		match variable_name:
			"1":
				l_line_edit.text = variable_value
			"10":
				l_line_edit.position.x = float(variable_value)
			"20":
				l_line_edit.position.y = float(variable_value) - l_line_edit.size.y
	l_line_edit.is_placing = false
	return l_line_edit
