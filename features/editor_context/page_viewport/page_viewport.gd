class_name PageViewport
extends SubViewportContainer


enum State {
	VIEWING,
	PLACING,
	EDITING,
}
@export var page_data: PageData:
	set = set_page_data
var unsaved_contents: Dictionary[PageData, PackedScene]
var state: State = State.VIEWING:
	set = set_state
@onready var layout: Panel = %Layout
@onready var contents_layer: CanvasLayer = %ContentsLayer
@onready var selection_manager: SelectionManager = %SelectionManager
@onready var grid: Grid = %Grid
@onready var viewport_camera: VewportCamera = %ViewportCamera
@onready var edit_properties_dialog: PropertiesDialog = %EditPropertiesDialog
@onready var reset_vew_button: Button = %ResetVewButton


func _ready() -> void:
	selection_manager.contents_layer = contents_layer
	if page_data:
		_update_page_viewport()
	reset_vew_button.pressed.connect(reset_view)


func _input(event: InputEvent) -> void:
	if event.is_action(&"open_properties") and event.is_pressed():
		edit_properties_dialog.activate()
		get_viewport().set_input_as_handled()


func set_page_data(_page_data: PageData) -> void:
	var project_data: ProjectData
	if page_data:
		project_data = page_data.project_data.get_ref()
		project_data.closed.disconnect(_on_project_data_closed)
		page_data.grid_interval_changed.disconnect(_on_page_data_grid_interval_changed)
		if not page_data.is_saved:
			unsaved_contents[page_data] = pack_contents()
	page_data = _page_data
	if is_node_ready():
		_update_page_viewport()
	project_data = page_data.project_data.get_ref()
	page_data.grid_interval_changed.connect(_on_page_data_grid_interval_changed)
	project_data.closed.connect(_on_project_data_closed)
	if not page_data.changed.is_connected(_on_page_data_changed):
		page_data.changed.connect(_on_page_data_changed)


func _update_page_viewport() -> void:
	_clear_contents()
	if not page_data:
		## TODO handle case for closing page
		if not Engine.is_editor_hint():
			name = ""
		return
	name = page_data.name + " " + page_data.description
	if unsaved_contents.has(page_data):
		_add_contents(unsaved_contents[page_data])
	else:
		_add_contents(page_data.contents)
	set_layout_size(page_data.size)
	if not page_data.size_changed.is_connected(set_layout_size):
		page_data.size_changed.connect(set_layout_size)
	grid.interval = page_data.grid_interval


func set_layout_size(page_size: Vector2) -> void:
	var layout_size: Vector2
	layout_size.x = Units.mm_to_px(page_size.x)
	layout_size.y = Units.mm_to_px(page_size.y)
	if layout:
		layout.custom_maximum_size = layout_size
		layout.size = layout_size


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


func save() -> void:
	if page_data:
		page_data.contents = pack_contents()
		page_data.is_saved = true
		if unsaved_contents.has(page_data):
			unsaved_contents.erase(page_data)
		ResourceSaver.save(page_data)
	for _page_data: PageData in unsaved_contents.keys():
		_page_data.contents = unsaved_contents[_page_data]
		_page_data.is_saved = true
		ResourceSaver.save(_page_data)
		unsaved_contents.erase(_page_data)


func add_graphics(graphics: Node) -> void:
	page_data.is_saved = false
	if graphics is PolyLine2D:
		add_poly_line_2d(graphics as PolyLine2D)
	if graphics is LLineEdit:
		add_l_line_edit(graphics as LLineEdit)
	contents_layer.add_child(graphics)
	graphics.owner = contents_layer


func add_poly_line_2d(poly_line_2d: PolyLine2D) -> void:
	poly_line_2d.page_data = weakref(page_data)
	poly_line_2d.page_viewport = self
	poly_line_2d.changed.connect(_on_page_data_content_changed)
	poly_line_2d.deleted.connect(_on_page_data_content_changed)
	poly_line_2d.finished_drawing.connect(set_state.bind(State.VIEWING), CONNECT_ONE_SHOT)


func add_l_line_edit(l_line_edit: LLineEdit) -> void:
	l_line_edit.page_data = weakref(page_data)
	l_line_edit.page_viewport = self
	l_line_edit.changed.connect(_on_page_data_content_changed)
	l_line_edit.deleted.connect(_on_page_data_content_changed)
	l_line_edit.editing_toggled.connect(_on_l_line_edit_editing_toggled)
	l_line_edit.finished_placing.connect(set_state.bind(State.EDITING), CONNECT_ONE_SHOT)


func _on_l_line_edit_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		state = State.EDITING
	else:
		state = State.VIEWING


func _on_page_data_content_changed() -> void:
	page_data.is_saved = false


func pack_contents() -> PackedScene:
	var contents: PackedScene = PackedScene.new()
	contents.pack(contents_layer)
	return contents


func set_can_select(can_select: bool) -> void:
	selection_manager.can_select = can_select


func _on_page_data_grid_interval_changed(grid_interval: float) -> void:
	grid.interval = grid_interval


func _on_project_data_closed() -> void:
	queue_free()


func get_place_position() -> Vector2:
	var interval: Vector2 = Vector2(Units.mm_to_px(grid.interval), Units.mm_to_px(grid.interval))
	var place_position: Vector2
	var local_mouse_position: Vector2 = viewport_camera.viewport.canvas_transform.affine_inverse() * viewport_camera.viewport.get_mouse_position()
	if grid.visible:
		place_position = snapped(local_mouse_position, interval)
	else:
		place_position = local_mouse_position
	return place_position


func set_state(_state: State) -> void:
	state = _state
	match state:
		State.VIEWING:
			set_can_select(true)
		State.PLACING:
			set_can_select(false)
		State.EDITING:
			set_can_select(false)


func reset_view() -> void:
	viewport_camera.viewport.canvas_transform = Transform2D.IDENTITY


func _on_page_data_changed() -> void:
	name = page_data.name + " " + page_data.description
