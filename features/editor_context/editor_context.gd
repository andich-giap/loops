class_name EditorContext
extends Panel


signal create_project_requested
signal open_project_requested
signal close_project_requested
@export var menu_button_bar_scene: PackedScene
@export var tool_bar_scene: PackedScene
@export var page_manager_scene: PackedScene
@export var dxf_inspector_scene: PackedScene
var _menu_button_bar_node: MenuButtonBar
var _tool_bar_node: ToolBar
var _page_manager_node: PageManager
var _dxf_inspector_node: DXFInspector
var _pages_tab_container: PagesTabContainer
var current_project: ProjectData
@onready var top_bar: VBoxContainer = %TopBar
@onready var h_split_container: HSplitContainer = %HSplitContainer
@onready var tab_container: TabContainer = %TabContainer


func _ready() -> void:
	build()
	bind_dependencies()
	setup()


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
	_menu_button_bar_node.close_project_requested.connect(close_project_requested.emit)
	_menu_button_bar_node.show_page_manager_requested.connect(handle_show_page_manager)
	
	_tool_bar_node.add_draw_line_requested.connect(handle_add_draw_line)
	_tool_bar_node.add_text_requested.connect(handle_add_text)
	_tool_bar_node.ortho_requested.connect(handle_ortho_toggle)
	_tool_bar_node.grid_requested.connect(handle_grid_toggle)


func handle_show_page_manager() -> void:
	pass


func handle_add_draw_line() -> void:
	pass


func handle_add_text() -> void:
	pass


func handle_ortho_toggle(toggled_on: bool) -> void:
	pass


func handle_grid_toggle(toggled_on: bool) -> void:
	pass
