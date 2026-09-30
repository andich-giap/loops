class_name MainMenuContext
extends Control


signal create_project_requested
signal open_project_requested(path: String)
@onready var create_project_button: Button = %CreateProjectButton
@onready var open_project_button: Button = %OpenProjectButton
@onready var recent_projects_container: VBoxContainer = %RecentProjectsContainer
var recent_projects: Array[String]


func build() -> void:
	var recent_projects_array: Array = SettingsManager.get_value(SettingsManager.RECENT_PROJECTS_KEY)
	recent_projects.append_array(recent_projects_array)
	for project_path: String in recent_projects:
		add_recent_project(project_path)


func bind_dependencies() -> void:
	pass


func setup() -> void:
	create_project_button.pressed.connect(create_project_requested.emit)
	open_project_button.pressed.connect(open_project_requested.emit)
	#TODO add recent projects


func add_recent_project(path: String) -> void:
	print(path)
