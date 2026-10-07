class_name ModesBar
extends HBoxContainer
 ## A bar that provides buttons to toggle grid visibility or ortho mode.


signal ortho_requested(toggled_on: bool) ## Emitted for [EditorContext] to toggle current pages [member Grid.is_orthogonal].
signal grid_requested(toggled_on: bool) ## Emitted for [EditorContext] to toggle current pages [member Grid.visible].
@onready var ortho_button: Button = $Ortho ## A button that triggers [method ortho_requested.emit]
@onready var grid_button: Button = $Grid ## A button that triggers [method grid_requested.emit]


func _ready() -> void:
	ortho_button.toggled.connect(ortho_requested.emit)
	grid_button.toggled.connect(grid_requested.emit)
	if ortho_button.button_pressed:
		ortho_requested.emit(true)
	if grid_button.button_pressed:
		grid_requested.emit(true)
