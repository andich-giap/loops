extends Node


@onready var button_bar: ButtonBar = %ButtonBar
@onready var create_new_project_dialog: ConfirmationDialog = %CreateNewProjectDialog
@onready var page_manager: PageManager = %PageManager
@onready var properties_dialog: PropertiesDialog = %PropertiesDialog
@onready var pages_tab_container: PagesTabContainer = %PagesTabContainer
@onready var open_project_file_dialog: FileDialog = %OpenProjectFileDialog
var current_project: ProjectData


func _ready() -> void:
	if not Global.program_state.opened_projects.is_empty():
		current_project = Global.program_state.opened_projects[0]
	button_bar.project_menu_item_pressed.connect(_on_project_menu_button_index_pressed)
	for opened_project: ProjectData in Global.program_state.opened_projects:
		page_manager.add_project(opened_project)
		opened_project.closed.connect(_on_project_data_closed, CONNECT_APPEND_SOURCE_OBJECT)
	if Global.program_state.last_opened_page:
		pages_tab_container.open_page(Global.program_state.last_opened_page)


func _input(event: InputEvent) -> void:
	if event.is_action(&"save_project") and event.is_pressed() and current_project:
		get_tree().call_group("persists", "save")
	if event.is_action(&"open_properties"):
		properties_dialog.activate()


func _on_project_menu_button_index_pressed(index: int, project_menu_button: MenuButton) -> void:
	match project_menu_button.get_popup().get_item_text(index):
		"CREATE":
			create_new_project_dialog.visible = true
		"OPEN":
			open_project()
		"CLOSE":
			close_project()


func get_editable_properties(object: Object) -> Array[Dictionary]:
	var property_list: Array[Dictionary] = object.get_property_list()
	var editable_properties: Array[Dictionary] = []
	for property: Dictionary in property_list:
		var export_var_usage: int = PROPERTY_USAGE_STORAGE + PROPERTY_USAGE_EDITOR + PROPERTY_USAGE_SCRIPT_VARIABLE
		if property["type"] == TYPE_NIL \
			or not property["usage"] == PROPERTY_USAGE_SCRIPT_VARIABLE \
			and not property["usage"] == export_var_usage:
			continue
		editable_properties.append(property)
	return editable_properties


func open_project() -> void:
	open_project_file_dialog.visible = true


func close_project() -> void:
	if current_project:
		current_project.close()


func save() -> void:
	return
	#ResourceSaver.save(current_project)


func _on_project_data_closed(project_data: ProjectData) -> void:
	project_data.closed.disconnect(_on_project_data_closed)
	Global.program_state.opened_projects.erase(project_data)
	ResourceSaver.save(Global.program_state)


func _on_create_new_project_dialog_new_project_created(project_data: ProjectData) -> void:
	add_project(project_data)


func add_project(project_data: ProjectData) -> void:
	Global.program_state.opened_projects.append(project_data)
	project_data.closed.connect(_on_project_data_closed, CONNECT_APPEND_SOURCE_OBJECT)
	ResourceSaver.save(Global.program_state)
	page_manager.add_project(project_data)


func _on_page_manager_project_tree_item_selected(project_data: ProjectData, _item: TreeItem) -> void:
	current_project = project_data


func _on_pages_tab_container_tab_changed(tab: int) -> void:
	if tab == -1:
		return
	var page_viewport: PageViewport = pages_tab_container.get_tab_control(tab)
	if page_viewport.page_data and page_viewport.page_data.project_data:
		current_project = page_viewport.page_data.project_data.get_ref()
	pages_tab_container.set_last_opened_page()


func _on_page_manager_page_opened(page_data: PageData) -> void:
	if not page_data.project_data:
		return
	var project_data: ProjectData = page_data.project_data.get_ref()
	current_project = project_data


func _on_open_project_file_dialog_file_selected(path: String) -> void:
	var resource: Resource = ResourceLoader.load(path)
	if not resource is ProjectData:
		return
	var project_data: ProjectData = resource
	add_project(project_data)
