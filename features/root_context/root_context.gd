class_name RootContext
extends Node


@export var main_menu_context_scene: PackedScene
@export var editor_context_scene: PackedScene
var current_project: ProjectData
var _main_menu_context_node: MainMenuContext
var _editor_context_node: EditorContext


func _ready() -> void:
	build()
	bind_dependencies()
	setup()


func build() -> void:
	_main_menu_context_node = main_menu_context_scene.instantiate()
	_editor_context_node = editor_context_scene.instantiate()
	
	add_child(_main_menu_context_node)
	add_child(_editor_context_node)


func bind_dependencies() -> void:
	pass


func setup() -> void:
	_main_menu_context_node.build()
	_main_menu_context_node.bind_dependencies()
	_main_menu_context_node.setup()
	
	_editor_context_node.build()
	_editor_context_node.bind_dependencies()
	_editor_context_node.setup()
	_editor_context_node.hide()
	
	_main_menu_context_node.project_created.connect(handle_project_created)
	_main_menu_context_node.open_project_requested.connect(handle_open_project)


func handle_project_created(project_data: ProjectData) -> void:
	handle_open_project(project_data.resource_path)


func handle_open_project(path: String) -> void:
	pass


func open_loaded_project(project_data: ProjectData) -> void:
	pass


func handle_close_project() -> void:
	current_project.close()


func handle_save() -> void:
	pass


func _on_create_new_project_dialog_new_project_created(project_data: ProjectData) -> void:
	add_project(project_data)


func add_project(project_data: ProjectData) -> void:
	project_data.closed.connect(_on_project_data_closed, CONNECT_APPEND_SOURCE_OBJECT)


func _on_project_data_closed(project_data: ProjectData) -> void:
	project_data.closed.disconnect(_on_project_data_closed)


#func _input(event: InputEvent) -> void:
	#if event.is_action(&"save_project") and event.is_pressed() and current_project:
		#get_tree().call_group("persists", "save")


#func _on_project_menu_button_index_pressed(index: int, project_menu_button: MenuButton) -> void:
	#match project_menu_button.get_popup().get_item_text(index):
		#"CREATE":
			#create_project()
		#"OPEN":
			#handle_open_project()
		#"CLOSE":
			#close_project()


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


#func _on_page_manager_page_opened(page_data: PageData) -> void:
	#if not page_data.project_data:
		#return
	#var project_data: ProjectData = page_data.project_data.get_ref()
	#current_project = project_data


#func _on_pages_tab_container_tab_changed(tab: int) -> void:
	#if tab == -1:
		#return


#func _on_page_manager_project_tree_item_selected(project_data: ProjectData, _item: TreeItem) -> void:
	#current_project = project_data
