class_name MainMenuContext
extends Control


signal create_project_requested
signal open_project_requested(path: String)
@onready var create_project_button: Button = %CreateProjectButton
@onready var open_project_button: Button = %OpenProjectButton
@onready var recent_projects_container: VBoxContainer = %RecentProjectsContainer


func build() -> void:
	pass


func bind_dependencies() -> void:
	pass


func setup() -> void:
	create_project_button.pressed.connect(create_project_requested.emit)
	open_project_button.pressed.connect(open_project_requested.emit)
	#TODO add recent projects
