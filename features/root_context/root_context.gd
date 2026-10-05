class_name RootContext
extends Node


@export var main_menu_context_scene: PackedScene
@export var editor_context_scene: PackedScene
var _current_project: ProjectData
var _opened_projects: Array[ProjectData]
var _main_menu_context_node: MainMenuContext
var _editor_context_node: EditorContext
@onready var create_project_dialog: CreateProjectDialog = %CreateProjectDialog
@onready var open_project_file_dialog: FileDialog = %OpenProjectFileDialog
@onready var save_notification: Notification = %SaveNotification


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
	SettingsManager.load_files()
	_main_menu_context_node.build()
	_main_menu_context_node.bind_dependencies()
	_main_menu_context_node.setup()
	
	_editor_context_node.build()
	_editor_context_node.bind_dependencies()
	_editor_context_node.setup()
	_editor_context_node.hide()
	
	_main_menu_context_node.create_project_requested.connect(_handle_create_project)
	_main_menu_context_node.open_project_requested.connect(_handle_open_project)
	
	_editor_context_node.create_project_requested.connect(_handle_create_project)
	_editor_context_node.open_project_requested.connect(_handle_open_project)
	_editor_context_node.close_project_requested.connect(_handle_close_project)
	
	create_project_dialog.create_project_requested.connect(create_project)
	open_project_file_dialog.file_selected.connect(_handle_project_file_selected)


func _handle_create_project() -> void:
	create_project_dialog.show()


func create_project(project_name: String, project_path: String) -> void:
	var project_data: ProjectData = ProjectData.new()
	project_data.name = project_name
	project_data.resource_path = project_path
	ResourceSaver.save(project_data)
	_create_contents_directories(project_data.resource_path.get_basename())
	_on_project_created(project_data)


func _create_contents_directories(project_base_name: String) -> void:
	var contents_path: String = project_base_name + "_loops_contents"
	DirAccess.make_dir_absolute(contents_path)
	DirAccess.make_dir_absolute(contents_path+"/pages")


func _handle_open_project(path: String = "") -> void:
	if not path:
		open_project_file_dialog.show()
		return
	var project_data: ProjectData = load_project(path)
	if project_data:
		open_project(project_data)


func _on_project_created(project_data: ProjectData) -> void:
	open_project(project_data)


func load_project(path: String) -> ProjectData:
	var project_data: ProjectData
	if FileAccess.file_exists(path):
		project_data = ResourceLoader.load(path)
	if project_data:
		return project_data
	push_warning("Failed to load ProjectData from path: " + path)
	return null


func open_project(project_data: ProjectData) -> void:
	_main_menu_context_node.hide()
	_editor_context_node.show()
	_editor_context_node.open_project(project_data)
	add_recent_project(project_data.resource_path)
	_current_project = project_data
	_opened_projects.append(project_data)


func _handle_project_file_selected(path: String) -> void:
	var project_data: ProjectData = load_project(path)
	if project_data:
		open_project(project_data)


func _handle_close_project(project_data: ProjectData = null) -> void:
	close_project(project_data)
	if _opened_projects.is_empty():
		_editor_context_node.hide()
		_main_menu_context_node.show()
	elif not _current_project:
		_current_project = _opened_projects[0]


func close_project(project_data: ProjectData = null) -> void:
	if project_data:
		_opened_projects.erase(project_data)
		project_data.close()
		return
	_opened_projects.erase(_current_project)
	_current_project.close()
	_current_project = null


func _handle_save() -> void:
	save()


func save() -> void:
	get_tree().call_group("persists", "save")
	save_notification.trigger()


func add_recent_project(project_path: String) -> void:
	if not FileAccess.file_exists(project_path):
		return
	var recent_projects: Array = SettingsManager.get_value(SettingsManager.RECENT_PROJECTS_KEY)
	recent_projects.erase(project_path)
	recent_projects.append(project_path)
	SettingsManager.set_value(SettingsManager.RECENT_PROJECTS_KEY, recent_projects)
	SettingsManager.save_by_key(SettingsManager.RECENT_PROJECTS_KEY)


func _input(event: InputEvent) -> void:
	if event.is_action(&"save_project") and event.is_pressed() and _current_project:
		_handle_save()
		get_viewport().set_input_as_handled()
