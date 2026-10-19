class_name PagesTabContainer
extends TabContainer
## Contains opened pages as [PageViewport]s.


signal unpress_modal_tool_buttons
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
	page_viewport.unpress_modal_tool_buttons.connect(unpress_modal_tool_buttons.emit)
	page_viewport.page_data = page_data
	add_child(page_viewport)


#region setters/getters
func get_current_page() -> PageViewport:
	if get_child_count() == 0:
		return null
	var tab: Control = get_current_tab_control()
	if tab is PageViewport:
		return tab
	return null
#endregion


## Triggers [ModalTool] activation in current [PageViewport] without selection.
func activate_modal_tool(modal_tool: GDScript) -> void:
	current_page.start_tool(modal_tool)


func _on_tool_bar_graphics_added(graphics: Node) -> void:
	var current_page_viewport: PageViewport = get_current_tab_control() as PageViewport
	if not current_page_viewport or not current_page_viewport.page_data:
		graphics.queue_free()
		return
	current_page_viewport.add_graphics(graphics)


func _on_grid_toggled(toggled_on: bool) -> void:
	for child: Node in get_children():
		if child is not PageViewport:
			continue
		var page_viewport: PageViewport = child
		page_viewport.grid.visible = toggled_on
