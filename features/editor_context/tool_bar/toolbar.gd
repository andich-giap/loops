class_name ToolBar
extends HBoxContainer
## Manages all the panels on the tool bar such as [DrawToolsPanel] and [ModesBar].


signal ortho_requested(toggled_on: bool) ## Emitted for [EditorContext] to toggle current pages [member Grid.is_orthogonal].
signal grid_requested(toggled_on: bool) ## Emitted for [EditorContext] to toggle current pages [member Grid.visible].
signal modal_tool_activation_requested(tool: ModalTool) ## Emitted for [EditorContext] to execute [ModalTool].
@onready var draw_tool_bar: ModalToolBar = %DrawToolsBar ## A tool bar that has buttons for adding [PolyLine2D], [LLineEdit] and other graphics.
@onready var modes_bar: ModesBar = %ModesBar ## A bar that provides buttons to toggle grid visibility or ortho mode.
@onready var modal_tools_bar: ModalToolBar = %ModalToolsBar


func _ready() -> void:
	draw_tool_bar.modal_tool_activation_requested.connect(modal_tool_activation_requested.emit)
	
	modes_bar.ortho_requested.connect(ortho_requested.emit)
	modes_bar.grid_requested.connect(grid_requested.emit)
	
	modal_tools_bar.modal_tool_activation_requested.connect(modal_tool_activation_requested.emit)


func unpress_modal_tool_buttons() -> void:
	var draw_tool_bar_pressed_button: Button = draw_tool_bar.button_group.get_pressed_button()
	var modal_tools_bar_pressed_button: Button = modal_tools_bar.button_group.get_pressed_button()
	if draw_tool_bar_pressed_button:
		draw_tool_bar_pressed_button.button_pressed = false
	if modal_tools_bar_pressed_button:
		modal_tools_bar_pressed_button.button_pressed = false
