class_name MenuButtonBar
extends HBoxContainer
## A menu bar at the top of the screen that show actions that are related to project, opening panels, etc.


signal create_project_requested ## Emitted for [RootContext] to create a new project.
signal open_project_requested ## Emitted for [RootContext] to open a project.
signal close_project_requested ## Emitted for [RootContext] to close the current project.
signal show_page_manager_requested ## Emitted for [EditorContext] to toggle [PageManager].
@onready var project_menu_button: MenuButton = $ProjectMenuButton ## Responsible for project actions.
@onready var view_menu_button: MenuButton = $ViewMenuButton ## Responsible for showing various panels and views.


func _ready() -> void:
	project_menu_button.get_popup().index_pressed.connect(_on_project_menu_button_popup_index_pressed)
	view_menu_button.get_popup().index_pressed.connect(_on_view_menu_button_popup_index_pressed)


func _on_project_menu_button_popup_index_pressed(index: int) -> void:
	match index:
		0:
			create_project_requested.emit()
		1:
			open_project_requested.emit()
		2:
			close_project_requested.emit()


func _on_view_menu_button_popup_index_pressed(index: int) -> void:
	match index:
		0:
			show_page_manager_requested.emit()
