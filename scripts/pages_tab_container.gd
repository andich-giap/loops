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
