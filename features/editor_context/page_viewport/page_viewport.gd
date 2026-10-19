class_name PageViewport
extends SubViewportContainer
## A viewport that shows [member PageData.contents].


signal copy_graphics_requested(graphics: Array[Node])
signal paste_graphics_requested
signal unpress_modal_tool_buttons
enum Mode { ## Possible state when working with the page contents.
	IDLE, ## Default view for inspecting the contents visually.
	TOOL, ## Interactive state for placing or drawing graphics.
}
@export var page_data: PageData: ## Reference to [PageData].
	set = set_page_data
var _mode: Mode = Mode.IDLE ## The current [enum Mode].
var _unsaved_contents: Dictionary[PageData, PackedScene]
var _editing_nodes: Array[Node] = []
var _suspend_refresh: bool = false
var _tool_needs_selection: bool = false
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
@onready var sub_viewport: SubViewport = %SubViewport
@onready var snap_engine: SnapEngine = %SnapEngine
@onready var snapping_preview: SnappingPreview = %SnappingPreview


func _ready() -> void:
	_setup_snap_engine()
	
	selection_manager.contents_layer = contents_layer
	selection_manager.reset_query()
	selection_manager.selection_changed.connect(_on_selection_changed)
	
	if page_data:
		_update_page_viewport()
	
	reset_view_button.pressed.connect(reset_view)
	context_menu.hide()
	
	context_menu.index_pressed.connect(_on_context_menu_index_pressed)
	modal_tools_manager.preview_layer = modal_tool_preview_layer
	modal_tools_manager.modal_tool_finished_executing.connect(_on_modal_tool_finished)
	modal_tools_manager.selection_requested.connect(request_selection)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action(&"close_viewport") and event.is_released():
		queue_free()


func _gui_input(event: InputEvent) -> void:
	if event.is_action(&"ui_cancel") and event.is_pressed():
		_handle_escape()
		accept_event()
		return
	
	# Priority 1: Node editing.
	if is_editing_nodes() and _is_click_outside_editing(event):
		_finish_all_editing()
		accept_event()
		return
	
	# Priority 2: ModalTool.handle_input().
	if is_tool_active():
		if _tool_needs_selection:
			_handle_selection_input(event)
		return
	
	# Priority 3: Idle-only input.
	if event.is_action(&"open_properties") and event.is_pressed():
		edit_properties_dialog.activate(_get_selected_nodes())
		accept_event()
		return
	
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_released():
				show_context_menu()
			accept_event()
			return
		
		if mouse_button_event.double_click:
			var hovered: Control = sub_viewport.gui_get_hovered_control()
			if hovered is LLineEdit:
				(hovered as LLineEdit).edit_text()
				return
	
	_handle_selection_input(event)


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


## Returns the possible place position takin into account snapping.
func get_snapped_position() -> SnapReceipt:
	var receipt: SnapReceipt = snap_engine.resolve_snap(contents_layer.get_children())
	return receipt


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
func start_tool(modal_tool: GDScript, nodes: Array[Node] = []) -> void:
	if is_tool_active():
		stop_tool()
	if is_editing_nodes():
		_finish_all_editing()
	if nodes.is_empty():
		nodes = _get_selected_nodes()
	_mode = Mode.TOOL
	gui_input.connect(modal_tools_manager.handle_input)
	_call_selected_nodes(&"remove_gizmos")
	modal_tools_manager.activate_modal_tool(modal_tool, nodes, self)
	_refresh_interaction()


## Deactivates modal tool execution.
func stop_tool(cancel: bool = true) -> void:
	if not is_tool_active():
		return
	_tool_needs_selection = false
	if cancel:
		modal_tools_manager.deactivate_modal_tool()
		if selection_manager.selection_changed.is_connected(_receive_selection):
			selection_manager.selection_changed.disconnect(_receive_selection)
	if gui_input.is_connected(modal_tools_manager.handle_input):
		gui_input.disconnect(modal_tools_manager.handle_input)
	modal_tools_manager.active_tool = null
	_mode = Mode.IDLE
	unpress_modal_tool_buttons.emit()
	snapping_preview.clear()
	_refresh_interaction()


## Sends the [SelectionQuery] to [member selection_manager].
func request_selection(query: SelectionQuery) -> void:
	_tool_needs_selection = true
	selection_manager.request_selection(query)
	selection_manager.selection_changed.connect(_receive_selection, CONNECT_ONE_SHOT)


func _receive_selection(receipt: SelectionReceipt) -> void:
	_tool_needs_selection = false
	modal_tools_manager.receive_selection(receipt)
	selection_manager.reset_query()


func _on_modal_tool_finished(receipt: ModalToolReceipt) -> void:
	receipt.apply_changes(self)
	page_data.is_saved = false
	selection_manager.reset_query()
	modal_tool_preview_layer.transform = Transform2D.IDENTITY
	get_viewport().set_input_as_handled()
	stop_tool(false)
#endregion


#region Node editing
func begin_node_edit(node: Node) -> void:
	if node in _editing_nodes:
		return
	_editing_nodes.append(node)
	if not _suspend_refresh:
		_refresh_interaction()


func end_node_edit(node: Node) -> void:
	_editing_nodes.erase(node)
	if not _suspend_refresh:
		_refresh_interaction()


func is_idle() -> bool:
	return _mode == Mode.IDLE and _editing_nodes.is_empty()


func is_editing_nodes() -> bool:
	return not _editing_nodes.is_empty()


func is_tool_active() -> bool:
	return _mode == Mode.TOOL


func _on_node_editing_toggled(toggled_on: bool, node: Node) -> void:
	if toggled_on:
		begin_node_edit(node)
	else:
		end_node_edit(node)


func _refresh_interaction() -> void:
	var idle: bool = is_idle()
	selection_manager.can_select = idle or _tool_needs_selection
	snapping_preview.visible = not idle
	modal_tool_preview_layer.visible = is_tool_active()


func _finish_all_editing() -> void:
	_suspend_refresh = true
	for node: Node in _editing_nodes.duplicate(): # Safe for erasing from _editing_nodes midway of the for loop.
		Utils.call_node(node, &"finish_editing")
		end_node_edit(node)
	_suspend_refresh = false
	_refresh_interaction()
#endregion


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
	poly_line_2d.points_editing_toggled.connect(_on_node_editing_toggled.bind(poly_line_2d))


func _add_l_line_edit(l_line_edit: LLineEdit) -> void:
	l_line_edit._page_viewport = self
	l_line_edit.changed.connect(_on_page_data_content_changed)
	l_line_edit.deleted.connect(_on_page_data_content_changed)
	l_line_edit.text_editing_toggled.connect(_on_node_editing_toggled.bind(l_line_edit))
	l_line_edit.position_editing_toggled.connect(_on_node_editing_toggled.bind(l_line_edit))
	l_line_edit.size = Vector2.ZERO


func _update_page_viewport() -> void:
	_editing_nodes.clear()
	_suspend_refresh = false
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
		_mode = Mode.TOOL
	else:
		_mode = Mode.IDLE
	get_viewport().set_input_as_handled()
	selection_manager.is_selecting = false


func _on_l_line_edit_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_mode = Mode.TOOL
	else:
		_mode = Mode.IDLE
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
			start_tool(MoveModalTool, _get_selected_nodes())
		"DUPLICATE":
			start_tool(DuplicateModalTool, _get_selected_nodes())
		"DELETE":
			start_tool(DeleteModalTool, _get_selected_nodes())
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


func _is_click_outside_editing(event: InputEvent) -> bool:
	if not event is InputEventMouseButton:
		return false
	var mouse_event: InputEventMouseButton = event
	if not mouse_event.is_pressed() or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return false
	var hovered: Control = sub_viewport.gui_get_hovered_control()
	if hovered is LLineEdit:
		return false
	return true


func _get_selected_nodes() -> Array[Node]:
	return selection_manager.get_current_selection().selected_nodes


func _call_selected_nodes(method: StringName) -> void:
	var nodes: Array[Node] = _get_selected_nodes()
	if not nodes.is_empty():
		Utils.call_nodes(nodes, method)


func _setup_snap_engine() -> void:
	var grid_constraint: GridConstraint = GridConstraint.new(grid)
	grid_constraint.priority = 0
	
	var vertex_constraint: VertexConstraint = VertexConstraint.new()
	vertex_constraint.priority = 1
	
	var midpoint_constraint: MidpointConstraint = MidpointConstraint.new()
	midpoint_constraint.priority = 1
	
	snap_engine.snap_constraints = [
		grid_constraint,
		vertex_constraint,
		midpoint_constraint,
	]
	snap_engine.viewport = sub_viewport
	snap_engine.snap_changed.connect(snapping_preview.update)


func _handle_escape() -> void:
	if is_tool_active():
		stop_tool(true)
		return
	if is_editing_nodes():
		_finish_all_editing()
		return
	selection_manager.clear_selection()
