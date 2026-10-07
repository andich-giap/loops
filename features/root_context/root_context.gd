class_name RootContext
extends Node
## The root of the program. Acts as a starting point and builds main menu and editor contexts.


@export var main_menu_context_scene: PackedScene ## [MainMenuContext] that gets build on program start.
@export var editor_context_scene: PackedScene ## [EditorContext] that gets build on program start.
var current_project: ProjectData ## Currently opened and focused project.
var _opened_projects: Array[ProjectData]
var _main_menu_context_node: MainMenuContext
var _editor_context_node: EditorContext
@onready var create_project_dialog: CreateProjectDialog = %CreateProjectDialog ## Dialog that is responsible for creating a new project.
@onready var open_project_file_dialog: FileDialog = %OpenProjectFileDialog ## A [FileDialog] that is responsible for opening a project.
@onready var save_notification: Notification = %SaveNotification ## A notification that appears on saving.


func _ready() -> void:
	build()
	bind_dependencies()
	setup()


func _input(event: InputEvent) -> void:
	if event.is_action(&"save_project") and event.is_pressed() and current_project:
		_handle_save()
		get_viewport().set_input_as_handled()


## Setting up self, instanciating and adding nodes.
func build() -> void:
	_main_menu_context_node = main_menu_context_scene.instantiate()
	_editor_context_node = editor_context_scene.instantiate()
	
	add_child(_main_menu_context_node)
	add_child(_editor_context_node)


## Parsing connection between nodes that need it.
func bind_dependencies() -> void:
	pass


## Setting up all the child contexts and establishing connections.
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


## Creates a project with the given [param project_name] and saves it in the
## [param project_path] without creating the dedicated folder
func create_project(project_name: String, project_path: String) -> void:
	var project_data: ProjectData = ProjectData.new()
	project_data.name = project_name
	project_data.resource_path = project_path
	ResourceSaver.save(project_data)
	_create_contents_directories(project_data.resource_path.get_basename())
	_on_project_created(project_data)


## Loads the project from [param path].
func load_project(path: String) -> ProjectData:
	var project_data: ProjectData
	if FileAccess.file_exists(path):
		project_data = ResourceLoader.load(path)
	if project_data:
		return project_data
	push_warning("Failed to load ProjectData from path: " + path)
	return null


## Opens a project. [param project_data] can be retrieved by loading via [method load_project].
func open_project(project_data: ProjectData) -> void:
	_main_menu_context_node.hide()
	_editor_context_node.show()
	_editor_context_node.open_project(project_data)
	_add_recent_project(project_data.resource_path)
	current_project = project_data
	_opened_projects.append(project_data)


## Closes a project, if [param project_data] is not provided then the
## [member current_project] is closed.
func close_project(project_data: ProjectData = null) -> void:
	if project_data:
		_opened_projects.erase(project_data)
		project_data.close()
		return
	_opened_projects.erase(current_project)
	current_project.close()
	current_project = null


## Saves everything with persists group
func save() -> void:
	get_tree().call_group("persists", "save")
	save_notification.trigger()


func _handle_create_project() -> void:
	create_project_dialog.show()


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


func _handle_project_file_selected(path: String) -> void:
	var project_data: ProjectData = load_project(path)
	if project_data:
		open_project(project_data)


func _handle_close_project(project_data: ProjectData = null) -> void:
	close_project(project_data)
	if _opened_projects.is_empty():
		_editor_context_node.hide()
		_main_menu_context_node.show()
	elif not current_project:
		current_project = _opened_projects[0]


func _handle_save() -> void:
	save()


## Adds a project path for the [MainMenuContext] to utilize.
func _add_recent_project(project_path: String) -> void:
	if not FileAccess.file_exists(project_path):
		return
	var recent_projects: Array = SettingsManager.get_value(SettingsManager.RECENT_PROJECTS_KEY)
	recent_projects.erase(project_path)
	recent_projects.append(project_path)
	SettingsManager.set_value(SettingsManager.RECENT_PROJECTS_KEY, recent_projects)
	SettingsManager.save_by_key(SettingsManager.RECENT_PROJECTS_KEY)
