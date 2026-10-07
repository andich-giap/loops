class_name PageViewport
extends SubViewportContainer
## A viewport that shows [member PageData.contents].


enum State { ## Possible state when working with the page contents.
	VIEWING, ## Default view for inspecting the contents visually.
	PLACING, ## Interactive state for placing or drawing graphics.
	EDITING, ## Interactive state for editing the text lines.
}
@export var page_data: PageData: ## Reference to [PageData].
	set = set_page_data
var _unsaved_contents: Dictionary[PageData, PackedScene]
var state: State = State.VIEWING: ## The current [enum State].
	set = set_state
@onready var layout: Panel = %Layout ## Reference to layout that sits behind the User access.
@onready var contents_layer: CanvasLayer = %ContentsLayer ## Reference to contents layer that holds [member PageData.contents].
@onready var selection_manager: SelectionManager = %SelectionManager ## Reference to [SelectionManager].
@onready var grid: Grid = %Grid ## Reference to [Grid].
@onready var viewport_camera: VewportCamera = %ViewportCamera ## Reference to [ViewportCamera].
@onready var edit_properties_dialog: PropertiesDialog = %EditPropertiesDialog ## Dialog that is used to edit the properties of the selected contents.
@onready var reset_vew_button: Button = %ResetVewButton ## Button for resetting the canvas transform of the viewport.


func _ready() -> void:
	selection_manager.contents_layer = contents_layer
	if page_data:
		_update_page_viewport()
	reset_vew_button.pressed.connect(reset_view)


func _input(event: InputEvent) -> void:
	if event.is_action(&"open_properties") and event.is_pressed():
		edit_properties_dialog.activate()
		get_viewport().set_input_as_handled()


#region setters/getters
func set_page_data(_page_data: PageData) -> void:
	var project_data: ProjectData
	if page_data:
		project_data = page_data.project_data.get_ref()
		project_data.closed.disconnect(_on_project_data_closed)
		page_data.grid_interval_changed.disconnect(_on_page_data_grid_interval_changed)
		if not page_data.is_saved:
			_unsaved_contents[page_data] = pack_contents()
	page_data = _page_data
	if is_node_ready():
		_update_page_viewport()
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
	contents_layer.add_child(graphics)
	graphics.owner = contents_layer


func _set_can_select(can_select: bool) -> void:
	selection_manager.can_select = can_select


func _set_layout_size(page_size: Vector2) -> void:
	var layout_size: Vector2
	layout_size.x = Units.mm_to_px(page_size.x)
	layout_size.y = Units.mm_to_px(page_size.y)
	if layout:
		layout.custom_maximum_size = layout_size
		layout.size = layout_size


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


func _add_poly_line_2d(poly_line_2d: PolyLine2D) -> void:
	poly_line_2d._page_viewport = self
	poly_line_2d.changed.connect(_on_page_data_content_changed)
	poly_line_2d.deleted.connect(_on_page_data_content_changed)
	poly_line_2d.finished_drawing.connect(set_state.bind(State.VIEWING), CONNECT_ONE_SHOT)


func _add_l_line_edit(l_line_edit: LLineEdit) -> void:
	l_line_edit._page_viewport = self
	l_line_edit.changed.connect(_on_page_data_content_changed)
	l_line_edit.deleted.connect(_on_page_data_content_changed)
	l_line_edit.editing_toggled.connect(_on_l_line_edit_editing_toggled)
	l_line_edit.finished_placing.connect(set_state.bind(State.EDITING), CONNECT_ONE_SHOT)


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
		node.queue_free()


func _add_contents(contents: PackedScene) -> void:
	if not contents:
		return
	var new_contents: Node = contents.instantiate()
	for child: Node in new_contents.get_children():
		child.owner = null
		child.reparent(contents_layer)
		child.owner = contents_layer
		child.set(&"page_viewport", self)
	new_contents.queue_free()


func _on_l_line_edit_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		state = State.EDITING
	else:
		state = State.VIEWING


func _on_page_data_content_changed() -> void:
	page_data.is_saved = false


func _on_page_data_grid_interval_changed(grid_interval: float) -> void:
	grid.interval = grid_interval


func _on_project_data_closed() -> void:
	queue_free()


func _on_page_data_changed() -> void:
	name = page_data.name + " " + page_data.description
