class_name MainMenuContext
extends Control


signal project_created(project_data: ProjectData)
signal open_project_requested(path: String)
@onready var create_project_button: Button = %CreateProjectButton
@onready var open_project_button: Button = %OpenProjectButton
@onready var recent_projects_container: VBoxContainer = %RecentProjectsContainer
@onready var create_project_dialog: CreateProjectDialog = %CreateProjectDialog
@onready var open_project_file_dialog: FileDialog = %OpenProjectFileDialog


func build() -> void:
	pass


func bind_dependencies() -> void:
	pass


func setup() -> void:
	create_project_button.pressed.connect(handle_create_project)
	open_project_button.pressed.connect(handle_open_project)
	
	create_project_dialog.project_created.connect(project_created.emit)
	open_project_file_dialog.file_selected.connect(handle_project_file_selected)
	
	#TODO add recent projects


func handle_create_project() -> void:
	create_project_dialog.show()


func handle_open_project() -> void:
	open_project_file_dialog.show()


func handle_project_file_selected(path: String) -> void:
	open_project_requested.emit(path)
