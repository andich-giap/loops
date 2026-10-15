class_name PageViewport
extends SubViewportContainer
## A viewport that shows [member PageData.contents].


signal copy_graphics_requested(graphics: Array[Node])
signal paste_graphics_requested
signal unpress_modal_tool_buttons
enum State { ## Possible state when working with the page contents.
	VIEWING, ## Default view for inspecting the contents visually.
	PLACING, ## Interactive state for placing or drawing graphics.
	EDITING, ## Interactive state for editing the text lines.
}
@export var page_data: PageData: ## Reference to [PageData].
	set = set_page_data
var state: State = State.VIEWING: ## The current [enum State].
	set = set_state
var _unsaved_contents: Dictionary[PageData, PackedScene]
@onready var layout: Panel = %Layout ## Reference to layout that sits behind the User access.
@onready var contents_layer: CanvasLayer = %ContentsLayer ## Reference to contents layer that holds [member PageData.contents].
@onready var selection_manager: SelectionManager = %SelectionManager ## Reference to [SelectionManager].
@onready var grid: Grid = %Grid ## Reference to [Grid].
@onready var viewport_camera: ViewportCamera = %ViewportCamera ## Reference to [ViewportCamera].
@onready var edit_properties_dialog: PropertiesDialog = %EditPropertiesDialog ## Dialog that is used to edit the properties of the selected contents.
@onready var reset_view_button: Button = %ResetViewButton ## Button for resetting the canvas transform of the viewport.
@onready var context_menu: PageViewportContextMenu = %PageViewportContextMenu
@onready var modal_tools_manager: ModalToolsManager = %ModalToolsManager
@onready var modal_tool_preview_layer: CanvasLayer = %ModalToolPreviewLayer


func _ready() -> void:
	selection_manager.contents_layer = contents_layer
	selection_manager.reset_query()
	selection_manager.selection_changed.connect(_on_selection_changed)
	
	if page_data:
		_update_page_viewport()
	
	reset_view_button.pressed.connect(reset_view)
	context_menu.hide()
	
	context_menu.index_pressed.connect(_on_context_menu_index_pressed)
	modal_tools_manager.preview_layer = modal_tool_preview_layer
	modal_tools_manager.modal_tool_finished_executing.connect(_on_modal_tool_finished_executing)
	modal_tools_manager.selection_requested.connect(request_selection)
	modal_tools_manager.execution_cancelled.connect(deactivate_modal_tool)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action(&"close_viewport") and event.is_released():
		queue_free()


func _gui_input(event: InputEvent) -> void:
	if event.is_action(&"open_properties") and event.is_pressed():
		edit_properties_dialog.activate(_get_selected_nodes())
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.button_index == MouseButton.MOUSE_BUTTON_RIGHT \
			and mouse_button_event.is_released() \
			and state == State.VIEWING:
			show_context_menu()
	if state == State.VIEWING and selection_manager.can_select:
		_handle_selection_input(event)
	else:
		selection_manager.selection_rect.size = Vector2.ZERO
		selection_manager.queue_redraw()


#region setters/getters
func set_page_data(_page_data: PageData) -> void:
	if page_data == _page_data:
		return
	var project_data: ProjectData
	if page_data:
		project_data = page_data.project_data.get_ref()
		if project_data:
			project_data.closed.disconnect(_on_project_data_closed)
		page_data.grid_interval_changed.disconnect(_on_page_data_grid_interval_changed)
		if not page_data.is_saved:
			_unsaved_contents[page_data] = pack_contents()
	page_data = _page_data
	if is_node_ready():
		_update_page_viewport()
	if page_data.project_data:
		project_data = page_data.project_data.get_ref()
		page_data.grid_interval_changed.connect(_on_page_data_grid_interval_changed)
		project_data.closed.connect(_on_project_data_closed)
	if not page_data.changed.is_connected(_on_page_data_changed):
		page_data.changed.connect(_on_page_data_changed)


func set_state(_state: State) -> void:
	state = _state
	match state:
		State.VIEWING:
			_set_can_select(true)
		State.PLACING:
			_set_can_select(false)
		State.EDITING:
			_set_can_select(false)
#endregion


## Saves [member PageData.contents].
func save() -> void:
	if page_data:
		page_data.contents = pack_contents()
		page_data.is_saved = true
		if _unsaved_contents.has(page_data):
			_unsaved_contents.erase(page_data)
		ResourceSaver.save(page_data)
	for _page_data: PageData in _unsaved_contents.keys():
		_page_data.contents = _unsaved_contents[_page_data]
		_page_data.is_saved = true
		ResourceSaver.save(_page_data)
		_unsaved_contents.erase(_page_data)


## Adds graphics to the [member contents_layer].
func add_graphics(graphics: Node) -> void:
	page_data.is_saved = false
	if graphics is PolyLine2D:
		_add_poly_line_2d(graphics as PolyLine2D)
	if graphics is LLineEdit:
		_add_l_line_edit(graphics as LLineEdit)
	if not graphics.get_parent() == contents_layer:
		contents_layer.add_child(graphics)
	graphics.owner = contents_layer


## Returns the possible place position takin into account grid if it is visible.
func get_place_position() -> Vector2:
	var interval: Vector2 = Vector2(Units.mm_to_px(grid.interval), Units.mm_to_px(grid.interval))
	var place_position: Vector2
	var local_mouse_position: Vector2 = viewport_camera.viewport.canvas_transform.affine_inverse() * viewport_camera.viewport.get_mouse_position()
	if grid.visible:
		place_position = snapped(local_mouse_position, interval)
	else:
		place_position = local_mouse_position
	return place_position


## Pack the contents to the scene.
func pack_contents() -> PackedScene:
	var contents: PackedScene = PackedScene.new()
	contents.pack(contents_layer)
	return contents


## Resets the canvas transform of the viewport.
func reset_view() -> void:
	viewport_camera.viewport.canvas_transform = Transform2D.IDENTITY


## Activates [member context_menu].
func show_context_menu() -> void:
	context_menu.position = get_global_mouse_position()
	if _get_selected_nodes():
		context_menu.show_items(context_menu.GRAPHICS_SELECTED_ITEMS)
	else:
		context_menu.show_items(context_menu.NO_SELECTION_ITEMS)
	context_menu.show()


func copy_graphics(graphics: Array[Node]) -> void:
	if graphics.is_empty():
		return
	copy_graphics_requested.emit(graphics)


func cut_graphics(graphics: Array[Node]) -> void:
	if graphics.is_empty():
		return
	copy_graphics(graphics)
	for node: Node in graphics:
		node.queue_free()


#region ModalTools
## Activates modal tool execution.
func activate_modal_tool(modal_tool: GDScript, graphics: Array[Node] = []) -> void:
	if not graphics:
		graphics = _get_selected_nodes()
	deactivate_modal_tool()
	_set_can_select(false)
	gui_input.connect(modal_tools_manager.handle_input)
	_call_selected_nodes(&"remove_gizmos")
	modal_tools_manager.activate_modal_tool(modal_tool, graphics)


## Deactivates modal tool execution.
func deactivate_modal_tool() -> void:
	if gui_input.is_connected(modal_tools_manager.handle_input):
		gui_input.disconnect(modal_tools_manager.handle_input)
	modal_tools_manager.deactivate_modal_tool()


## Sends the [SelectionQuery] to [member selection_manager].
func request_selection(query: SelectionQuery) -> void:
	selection_manager.request_selection(query)
	selection_manager.selection_changed.connect(_receive_selection, CONNECT_ONE_SHOT)


func _receive_selection(receipt: SelectionReceipt) -> void:
	modal_tools_manager.receive_selection(receipt)
	selection_manager.reset_query()
	_set_can_select(false)


func _on_modal_tool_finished_executing(receipt: ModalToolReceipt) -> void:
	receipt.apply_changes(self)
	page_data.is_saved = false
	_set_can_select(true)
	selection_manager.reset_query()
	gui_input.disconnect(modal_tools_manager.handle_input)
	modal_tool_preview_layer.transform = Transform2D.IDENTITY
	unpress_modal_tool_buttons.emit()
	get_viewport().set_input_as_handled()
#endregion


func _set_can_select(can_select: bool) -> void:
	selection_manager.can_select = can_select


func _set_layout_size(page_size: Vector2) -> void:
	var layout_size: Vector2
	layout_size.x = Units.mm_to_px(page_size.x)
	layout_size.y = Units.mm_to_px(page_size.y)
	if layout:
		layout.custom_maximum_size = layout_size
		layout.size = layout_size


func _add_poly_line_2d(poly_line_2d: PolyLine2D) -> void:
	poly_line_2d._page_viewport = self
	poly_line_2d.changed.connect(_on_page_data_content_changed)
	poly_line_2d.deleted.connect(_on_page_data_content_changed)
	poly_line_2d.finished_drawing.connect(set_state.bind(State.VIEWING), CONNECT_ONE_SHOT)
	poly_line_2d.points_editing_toggled.connect(_on_poly_line_2d_point_editing_toggled)


func _add_l_line_edit(l_line_edit: LLineEdit) -> void:
	l_line_edit._page_viewport = self
	l_line_edit.changed.connect(_on_page_data_content_changed)
	l_line_edit.deleted.connect(_on_page_data_content_changed)
	l_line_edit.text_editing_toggled.connect(_on_l_line_edit_editing_toggled)
	l_line_edit.finished_placing.connect(set_state.bind(State.EDITING), CONNECT_ONE_SHOT)
	l_line_edit.position_editing_toggled.connect(_on_l_line_edit_editing_toggled)
	l_line_edit.size = Vector2.ZERO


func _update_page_viewport() -> void:
	_clear_contents()
	if not page_data:
		## TODO handle case for closing page
		if not Engine.is_editor_hint():
			name = ""
		return
	name = page_data.name + " " + page_data.description
	if _unsaved_contents.has(page_data):
		_add_contents(_unsaved_contents[page_data])
	else:
		_add_contents(page_data.contents)
	_set_layout_size(page_data.size)
	if not page_data.size_changed.is_connected(_set_layout_size):
		page_data.size_changed.connect(_set_layout_size)
	grid.interval = page_data.grid_interval


func _clear_contents() -> void:
	for node: Node in contents_layer.get_children():
		contents_layer.remove_child(node)
		node.queue_free()


func _add_contents(contents: PackedScene) -> void:
	if not contents:
		return
	var new_contents: Node = contents.instantiate()
	for child: Node in new_contents.get_children():
		child.owner = null
		child.reparent(contents_layer)
		add_graphics(child)
	new_contents.queue_free()
	page_data.is_saved = true


func _on_poly_line_2d_point_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		state = State.EDITING
	else:
		state = State.VIEWING
	get_viewport().set_input_as_handled()
	selection_manager.is_selecting = false


func _on_l_line_edit_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		state = State.EDITING
	else:
		state = State.VIEWING
	get_viewport().set_input_as_handled()
	selection_manager.is_selecting = false


func _on_page_data_content_changed() -> void:
	page_data.is_saved = false


func _on_page_data_grid_interval_changed(grid_interval: float) -> void:
	grid.interval = grid_interval


func _on_project_data_closed() -> void:
	queue_free()


func _on_page_data_changed() -> void:
	name = page_data.name + " " + page_data.description


func _on_context_menu_index_pressed(index: int) -> void:
	var action: String = context_menu.get_item_text(index)
	match action:
		"COPY":
			copy_graphics(_get_selected_nodes())
		"CUT":
			cut_graphics(_get_selected_nodes())
		"PASTE":
			paste_graphics_requested.emit()
		"MOVE":
			activate_modal_tool(MoveModalTool, _get_selected_nodes())
		"DUPLICATE":
			activate_modal_tool(DuplicateModalTool, _get_selected_nodes())
		"DELETE":
			pass
		"PROPERTIES":
			edit_properties_dialog.activate(_get_selected_nodes())


func _on_selection_changed(_receipt: SelectionReceipt) -> void:
	pass


func _handle_selection_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.shift_pressed:
			selection_manager.set_selection_mode(SelectionQuery.Mode.ADD)
		elif mouse_button_event.alt_pressed:
			selection_manager.set_selection_mode(SelectionQuery.Mode.SUBTRACT)
		else:
			selection_manager.set_selection_mode(SelectionQuery.Mode.REPLACE)
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button_event.is_pressed():
				selection_manager.is_selecting = true
				selection_manager.selection_rect.position = selection_manager.get_local_mouse_position()
			else:
				if selection_manager.selection_rect.size.is_zero_approx():
					selection_manager.selection_rect.position = (
						selection_manager.get_local_mouse_position() 
						- selection_manager.get_single_click_vector() / 2.0
					)
					selection_manager.selection_rect.size = selection_manager.get_single_click_vector()
				selection_manager.is_selecting = false
				selection_manager.request_user_selection_check()
				selection_manager.queue_redraw()
				return
	
	if event is InputEventMouseMotion and selection_manager.is_selecting:
		selection_manager.selection_rect.end = selection_manager.get_local_mouse_position()
		selection_manager.queue_redraw()
	
	
	if event.is_action(&"ui_cancel"):
		selection_manager.clear_selection()
		selection_manager.reset_query()
		selection_manager.can_select = true


func _get_selected_nodes() -> Array[Node]:
	return selection_manager.get_current_selection().selected_nodes


func _call_selected_nodes(method: StringName) -> void:
	var nodes: Array[Node] = _get_selected_nodes()
	Utils.call_nodes(nodes, method)
