class_name ToolBar
extends HBoxContainer
## Manages all the panels on the tool bar such as [DrawToolsPanel] and [ModesBar].


signal add_draw_line_requested ## Emitted for [EditorContext] to create [PolyLine2D].
signal add_text_requested ## Emitted for [EditorContext] to create [LLineEdit].
signal ortho_requested(toggled_on: bool) ## Emitted for [EditorContext] to toggle current pages [member Grid.is_orthogonal].
signal grid_requested(toggled_on: bool) ## Emitted for [EditorContext] to toggle current pages [member Grid.visible].
@onready var draw_tool_bar: DrawToolBar = %DrawToolBar ## A tool bar that has buttons for adding [PolyLine2D], [LLineEdit] and other graphics.
@onready var modes_bar: ModesBar = %ModesBar ## A bar that provides buttons to toggle grid visibility or ortho mode.


func _ready() -> void:
	draw_tool_bar.add_draw_line_requested.connect(add_draw_line_requested.emit)
	draw_tool_bar.add_text_requested.connect(add_text_requested.emit)
	
	modes_bar.ortho_requested.connect(ortho_requested.emit)
	modes_bar.grid_requested.connect(grid_requested.emit)
