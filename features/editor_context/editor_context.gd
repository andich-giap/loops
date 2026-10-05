class_name EditorContext
extends Panel


signal create_project_requested
signal open_project_requested
signal close_project_requested(project_data: ProjectData)
@export var menu_button_bar_scene: PackedScene
@export var tool_bar_scene: PackedScene
@export var page_manager_scene: PackedScene
@export var dxf_inspector_scene: PackedScene
var _menu_button_bar_node: MenuButtonBar
var _tool_bar_node: ToolBar
var _page_manager_node: PageManager
var _dxf_inspector_node: DXFInspector
var _pages_tab_container: PagesTabContainer
@onready var top_bar: VBoxContainer = %TopBar
@onready var h_split_container: HSplitContainer = %HSplitContainer
@onready var tab_container: TabContainer = %TabContainer


func build() -> void:
	_menu_button_bar_node = menu_button_bar_scene.instantiate()
	_tool_bar_node = tool_bar_scene.instantiate()
	_page_manager_node = page_manager_scene.instantiate()
	_dxf_inspector_node = dxf_inspector_scene.instantiate()
	_pages_tab_container = PagesTabContainer.new()
	
	top_bar.add_child(_menu_button_bar_node)
	top_bar.add_child(_tool_bar_node)
	top_bar.move_child(_tool_bar_node, 0)
	top_bar.move_child(_menu_button_bar_node, 0)
	
	tab_container.add_child(_page_manager_node)
	tab_container.add_child(_dxf_inspector_node)
	h_split_container.add_child(_pages_tab_container)


func bind_dependencies() -> void:
	pass


func setup() -> void:
	_menu_button_bar_node.create_project_requested.connect(create_project_requested.emit)
	_menu_button_bar_node.open_project_requested.connect(open_project_requested.emit)
	_menu_button_bar_node.close_project_requested.connect(_handle_close_project)
	_menu_button_bar_node.show_page_manager_requested.connect(handle_show_page_manager)
	
	_tool_bar_node.add_draw_line_requested.connect(handle_add_draw_line)
	_tool_bar_node.add_text_requested.connect(handle_add_text)
	_tool_bar_node.ortho_requested.connect(handle_ortho_toggle)
	_tool_bar_node.grid_requested.connect(handle_grid_toggle)
	
	_page_manager_node.open_page_requested.connect(handle_open_page)
	_page_manager_node.close_project_requested.connect(_handle_close_project)


func _handle_close_project(project_data: ProjectData = null) -> void:
	close_project_requested.emit(project_data)


func handle_open_page(page_data: PageData) -> void:
	_pages_tab_container.open_page(page_data)


func handle_show_page_manager() -> void:
	_page_manager_node.show()
	_page_manager_node.grab_focus()


func handle_add_draw_line() -> void:
	var page: PageViewport = _pages_tab_container.current_page
	if not page:
		return
	var poly_line_2d: PolyLine2D = PolyLine2D.new(true)
	page.add_graphics(poly_line_2d)
	poly_line_2d.finished_drawing.connect(_unpress_draw_button)


func handle_add_text() -> void:
	var page: PageViewport = _pages_tab_container.current_page
	if not page:
		return
	var l_line_edit: LLineEdit = LLineEdit.new(true)
	page.add_graphics(l_line_edit)
	l_line_edit.finished_placing.connect(_unpress_draw_button)


func _unpress_draw_button() -> void:
	_tool_bar_node.draw_tool_bar.button_group.get_pressed_button().button_pressed = false


func handle_ortho_toggle(toggled_on: bool) -> void:
	Grid.is_orthogonal = toggled_on


func handle_grid_toggle(toggled_on: bool) -> void:
	for child: Node in _pages_tab_container.get_children():
		if child is not PageViewport:
			continue
		var page_viewport: PageViewport = child
		page_viewport.grid.visible = toggled_on


func open_project(project_data: ProjectData) -> void:
	_page_manager_node.open_project(project_data)
	var pages: Array[PageData] = project_data.pages.values()
	handle_open_page(pages[0])


#func get_editable_properties(object: Object) -> Array[Dictionary]:
	#var property_list: Array[Dictionary] = object.get_property_list()
	#var editable_properties: Array[Dictionary] = []
	#for property: Dictionary in property_list:
		#var export_var_usage: int = PROPERTY_USAGE_STORAGE + PROPERTY_USAGE_EDITOR + PROPERTY_USAGE_SCRIPT_VARIABLE
		#if property["type"] == TYPE_NIL \
			#or not property["usage"] == PROPERTY_USAGE_SCRIPT_VARIABLE \
			#and not property["usage"] == export_var_usage:
			#continue
		#editable_properties.append(property)
	#return editable_properties
