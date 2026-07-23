class_name ButtonBar
extends HBoxContainer


signal project_menu_item_pressed(index: int, project_menu_button: MenuButton)
@onready var project_menu_button: MenuButton = $ProjectMenuButton
@onready var view_menu_button: MenuButton = $ViewMenuButton


func _ready() -> void:
	project_menu_button.get_popup().index_pressed.connect(project_menu_item_pressed.emit.bind(project_menu_button))
	view_menu_button.get_popup().index_pressed.connect(_on_view_menu_button_index_pressed)


func _on_view_menu_button_index_pressed(index: int) -> void:
	match view_menu_button.get_popup().get_item_text(index):
		"PAGE_MANAGER":
			%PageManager.set(&"visible", true)
