@tool
class_name PageViewport
extends SubViewportContainer


@export var page_data: PageData:
	set = set_page_data
var unsaved_contents: Dictionary[PageData, PackedScene]
@onready var layout: Panel = $SubViewport/PageLayoutLayer/Layout
@onready var contents_layer: CanvasLayer = $SubViewport/ContentsLayer
@onready var selection_manager: SelectionManager = $SubViewport/SelectionLayer/SelectionManager
@onready var grid: Grid = $SubViewport/PageLayoutLayer/Layout/Grid


func _ready() -> void:
	if page_data and layout and contents_layer:
		_update_page_viewport()


func set_page_data(_page_data: PageData) -> void:
	var project_data: ProjectData
	if page_data:
		project_data = page_data.project_data.get_ref()
		project_data.closed.disconnect(_on_project_data_closed)
		page_data.grid_interval_changed.disconnect(_on_page_data_grid_interval_changed)
		if not page_data.is_saved:
			unsaved_contents[page_data] = pack_contents()
	page_data = _page_data
	if page_data and layout and contents_layer:
		_update_page_viewport()
	project_data = page_data.project_data.get_ref()
	page_data.grid_interval_changed.connect(_on_page_data_grid_interval_changed)
	project_data.closed.connect(_on_project_data_closed)


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


func add_graphics(graphics: Node2D) -> void:
	page_data.is_saved = false
	if graphics is PolyLine2D:
		add_poly_line_2d(graphics as PolyLine2D)
	contents_layer.add_child(graphics)
	graphics.owner = contents_layer


func add_poly_line_2d(poly_line_2d: PolyLine2D) -> void:
	poly_line_2d.page_data = weakref(page_data)
	poly_line_2d.changed.connect(_on_page_data_content_changed)
	poly_line_2d.deleted.connect(_on_page_data_content_changed)


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
