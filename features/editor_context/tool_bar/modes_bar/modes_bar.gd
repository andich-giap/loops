class_name ModesBar
extends HBoxContainer


signal ortho_requested(toggled_on: bool)
signal grid_requested(toggled_on: bool)
@onready var ortho: Button = $Ortho
@onready var grid: Button = $Grid


func _ready() -> void:
	ortho.toggled.connect(ortho_requested.emit)
	grid.toggled.connect(grid_requested.emit)
	if ortho.button_pressed:
		ortho_requested.emit(true)
	if grid.button_pressed:
		grid_requested.emit(true)
