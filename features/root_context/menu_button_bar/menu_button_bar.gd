class_name MenuButtonBar
extends HBoxContainer


signal create_project_requested
signal open_project_requested
signal close_project_requested
signal show_page_manager_requested
@onready var project_menu_button: MenuButton = $ProjectMenuButton
@onready var view_menu_button: MenuButton = $ViewMenuButton


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
