class_name MainMenuContext
extends Control
## Main menu of the program where the user can create and open projects.


signal create_project_requested ## Emitted when the [member create_project_button] is pressed.
signal open_project_requested(path: String) ## Emitted when the [member open_project_button] is pressed or recent project is selected.
@onready var create_project_button: Button = %CreateProjectButton ## Used for triggering emitting [signal create_project_requested].
@onready var open_project_button: Button = %OpenProjectButton ## Used for triggering emitting [signal open_project_requested].
@onready var recent_projects_container: VBoxContainer = %RecentProjectsContainer ## Contains the recent projects. Recent projects are retrieved via [constant SettingsManager.RECENT_PROJECTS_KEY].
var recent_projects: Array[String] ## Contains paths of recently opened projects.


## Setting up self, instanciating and adding nodes.
func build() -> void:
	var recent_projects_array: Array = SettingsManager.get_value(SettingsManager.RECENT_PROJECTS_KEY)
	recent_projects.append_array(recent_projects_array)
	recent_projects.reverse()
	for project_path: String in recent_projects:
		add_recent_project(project_path)


## Parsing connection between nodes that need it.
func bind_dependencies() -> void:
	pass


## Setting up all the child contexts and establishing connections.
func setup() -> void:
	create_project_button.pressed.connect(create_project_requested.emit)
	open_project_button.pressed.connect(open_project_requested.emit)
	#TODO add recent projects


## Adds recent project as using [param path].
func add_recent_project(path: String) -> void:
	var button: Button = Button.new()
	button.text = path
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(open_project_requested.emit.bind(path))
	recent_projects_container.add_child(button)
