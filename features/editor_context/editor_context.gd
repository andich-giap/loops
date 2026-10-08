class_name EditorContext
extends Panel
## The Editor of the program. Builds and connects all the parts of the editor.


signal create_project_requested ## Emitted for [RootContext] to create a new project.
signal open_project_requested ## Emitted for [RootContext] to open a project.
signal close_project_requested(project_data: ProjectData) ## Emitted to close a specified project.
@export var menu_button_bar_scene: PackedScene ## [MainMenuContext] that gets build on program start.
@export var tool_bar_scene: PackedScene ## [MainMenuContext] that gets build on program start.
@export var page_manager_scene: PackedScene ## [MainMenuContext] that gets build on program start.
@export var dxf_inspector_scene: PackedScene ## [MainMenuContext] that gets build on program start.
var _menu_button_bar_node: MenuButtonBar
var _tool_bar_node: ToolBar
var _page_manager_node: PageManager
var _dxf_inspector_node: DXFInspector
var _pages_tab_container: PagesTabContainer
@onready var top_bar: VBoxContainer = %TopBar ## A bar that contains a pallete of instruments such as [DrawToolBar] and [ModesBar].
@onready var h_split_container: HSplitContainer = %HSplitContainer ## Contains [PageManager] and other managers on the left side and [PagesTabContainer] with [PageViewport]s on the right side.
@onready var tab_container: TabContainer = %TabContainer ## Contains  ## Contains [PageManager] and other managers.


## Setting up self, instanciating and adding nodes.
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


## Parsing connection between nodes that need it.
func bind_dependencies() -> void:
	pass


## Setting up all the child contexts and establishing connections.
func setup() -> void:
	_menu_button_bar_node.create_project_requested.connect(create_project_requested.emit)
	_menu_button_bar_node.open_project_requested.connect(open_project_requested.emit)
	_menu_button_bar_node.close_project_requested.connect(_handle_close_project)
	_menu_button_bar_node.show_page_manager_requested.connect(toggle_page_manager)
	
	_tool_bar_node.add_draw_line_requested.connect(add_draw_line)
	_tool_bar_node.add_text_requested.connect(add_text)
	_tool_bar_node.ortho_requested.connect(toggle_ortho)
	_tool_bar_node.grid_requested.connect(toggle_grid)
	
	_page_manager_node.open_page_requested.connect(open_page)
	_page_manager_node.close_project_requested.connect(_handle_close_project)


## Opens the project with the given [param project_data]. [param project_data] can be retrieved via [method RootContext.load_project].
func open_project(project_data: ProjectData) -> void:
	_page_manager_node.open_project(project_data)
	var pages: Array[PageData] = project_data.pages.values()
	if not pages.is_empty():
		open_page(pages[0])


## Opens the page as a [PageViewport].
func open_page(page_data: PageData) -> void:
	_pages_tab_container.open_page(page_data)


## Shows or hides [PageManager].
func toggle_page_manager() -> void:
	if _page_manager_node.visible:
		_page_manager_node.hide()
	else:
		_page_manager_node.show()
		_page_manager_node.grab_focus()


## Turns on and off [member Grid.is_orthogonal].
func toggle_ortho(toggled_on: bool) -> void:
	Grid.is_orthogonal = toggled_on


## Shows or hides [member PageViewport.grid].
func toggle_grid(toggled_on: bool) -> void:
	for child: Node in _pages_tab_container.get_children():
		if child is not PageViewport:
			continue
		var page_viewport: PageViewport = child
		page_viewport.grid.visible = toggled_on


## Adds a [PolyLine2D] to the current [PageViewport].
func add_draw_line() -> void:
	var page: PageViewport = _pages_tab_container.current_page
	if not page:
		return
	var poly_line_2d: PolyLine2D = PolyLine2D.new(true)
	page.add_graphics(poly_line_2d)
	poly_line_2d.finished_drawing.connect(_unpress_draw_button)


## Adds a [LLineEdit] to the current [PageViewport].
func add_text() -> void:
	var page: PageViewport = _pages_tab_container.current_page
	if not page:
		return
	var l_line_edit: LLineEdit = LLineEdit.new(true)
	page.add_graphics(l_line_edit)
	l_line_edit.finished_placing.connect(_unpress_draw_button)


func _handle_close_project(project_data: ProjectData = null) -> void:
	close_project_requested.emit(project_data)


func _unpress_draw_button() -> void:
	_tool_bar_node.draw_tool_bar.button_group.get_pressed_button().button_pressed = false
