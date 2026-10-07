class_name PageManager
extends PanelContainer
## Responsible for displaying the project tree, adding, editing and
## requesting the opening of the pages.


signal project_selected(project_data: ProjectData, item: TreeItem) ## Emitted when the project tree item is clicked.
signal open_page_requested(page_data: PageData) ## Emitted when double-clicking on a page tree item or activating it in some way.
signal create_page_requested(page_data: PageData) ## Emitted when create option is selected from the [member context_menu].
signal close_project_requested(project_data: ProjectData) ## Emitted when close option is selected from the [member context_menu] when clicking on the project.
const PROJECT_CONTEXT_ITEMS: Array[StringName] = [ ## Context items that are available in the [member context_menu] when the project tree item is selected.
	"CREATE",
	"CLOSE",
	"COPY",
	"PASTE",
	"RENAME",
	"NUMBERING",
	"PROPERTIES",
]
var root: TreeItem ## The root of the [member tree].
@onready var tree: Tree = %PagesTree ## The [Tree] that may contain multiple projects with their pages.
@onready var context_menu: PopupMenu = %ContextMenu ## Context menu that displays options when right-clicking on the [member tree]s tree items.
@onready var new_page_dialog: CreateNewPageDialog = %NewPageDialog ## Dialog that is used to configure the information about a new page to be created.
@onready var number_pages_dialog: NumberPagesDialog = %NumberPagesDialog ## Dialog that is used to number the selected pages and children of [Designation] tree items.
@onready var page_properties_dialog: PagePropertiesDialog = %PagePropertiesDialog ## Dialog that displays the properties of the page and allow to edit them.


func _ready() -> void:
	root = tree.create_item()
	
	tree.item_mouse_selected.connect(_on_tree_item_mouse_selected)
	tree.item_activated.connect(_on_tree_item_activated)
	tree.item_edited.connect(_on_tree_item_edited)
	tree.gui_input.connect(_on_tree_gui_input)
	
	context_menu.index_pressed.connect(_on_context_menu_index_pressed)
	
	new_page_dialog.page_created.connect(_on_new_page_dialog_page_created)
	new_page_dialog.new_page_name_changed.connect(_on_new_page_dialog_new_page_name_changed)


## Opens the project with the given [param project_data]. [param project_data] can be retrieved via [method RootContext.load_project].
func open_project(project_data: ProjectData) -> void:
	var project_item: TreeItem = tree.create_item(root)
	project_item.set_metadata(0, project_data)
	project_item.set_text(0, project_data.name)
	project_item.set_editable(0, false)
	var pages: Array[PageData]
	for page_data: PageData in project_data.pages.values():
		page_data.project_data = weakref(project_data)
		page_data.name_changed.connect(project_data._on_page_data_name_changed.bind(page_data.name, page_data), CONNECT_ONE_SHOT)
		pages.append(page_data)
	pages.sort_custom(func(a: PageData, b: PageData) -> bool:
		return int(a.name) < int(b.name)
		)
	for page_data: PageData in pages:
		add_page(project_item, page_data)
	
	project_data.closed.connect(_on_project_data_closed, CONNECT_APPEND_SOURCE_OBJECT)


## Adds a page as a child of [param parent].
func add_page(parent: TreeItem, page_data: PageData) -> void:
	var page_tree_item: TreeItem = parent.create_child()
	page_tree_item.set_icon(0, PageData.PAGE_TYPE_ICONS[page_data.type])
	page_tree_item.set_text(0, page_data.name + " " + page_data.description)
	page_tree_item.set_metadata(0, page_data)
	page_data.changed.connect(_on_page_data_changed.bind(page_tree_item))


## Returns the tree items that are currently selected in the [member tree].
## If [param select_children] is [code]true[/code] then the method also
## returns any child nodes under the project or [Designation] tree items that are selected.
func get_selected_tree_items(select_children: bool = false) -> Array[TreeItem]:
	var selected_items: Array[TreeItem] = []
	var current_item: TreeItem = tree.get_next_selected(null)
	while current_item:
		if not selected_items.has(current_item):
			selected_items.append(current_item)
			if select_children:
				_select_children_recursive(current_item, selected_items)
		current_item = tree.get_next_selected(current_item)
	return selected_items


## Returns the pages that are currently selected in the [member tree]. If [param select_children]
## is [code]true[/code] then the method also returns any child nodes under
## the project or [Designation] tree items that are selected.
func get_selected_pages(select_children: bool = false) -> Array[PageData]:
	var page_datas: Array[PageData]
	var selected_tree_items: Array[TreeItem] = get_selected_tree_items(select_children)
	for tree_item: TreeItem in selected_tree_items:
		if tree_item.get_metadata(0) is not PageData:
			continue
		var page_data: PageData = tree_item.get_metadata(0)
		page_datas.append(page_data)
	return page_datas


## Returns the project that contains a specified [param child].
func get_project_from_child(child: TreeItem) -> ProjectData:
	if child.get_metadata(0) is ProjectData:
		return child.get_metadata(0)
	var parent: TreeItem = child.get_parent()
	while not parent.get_metadata(0) is ProjectData:
		parent = parent.get_parent()
	return parent.get_metadata(0)


func _on_tree_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	var selected_item: TreeItem = tree.get_item_at_position(mouse_position)
	project_selected.emit(get_project_from_child(selected_item), selected_item) 
	if not mouse_button_index == MOUSE_BUTTON_RIGHT:
		return
	var metadata: Resource = tree.get_selected().get_metadata(0)
	for index: int in range(context_menu.item_count):
		if not PROJECT_CONTEXT_ITEMS.has(context_menu.get_item_text(index)) and metadata is ProjectData:
			context_menu.set_item_disabled(index, true)
		else:
			context_menu.set_item_disabled(index, false)
	context_menu.position = mouse_position
	context_menu.visible = true


func _on_tree_item_activated() -> void:
	var selected_tree_item: TreeItem = tree.get_selected()
	var metadata: Variant = selected_tree_item.get_metadata(0)
	if selected_tree_item.get_metadata(0) is PageData:
		open_page_requested.emit(metadata)


func _on_tree_item_edited() -> void:
	var tree_item: TreeItem = tree.get_selected()
	var metadata: Variant = tree_item.get_metadata(0)
	if metadata is PageData:
		var page_data: PageData = metadata
		var project_data: ProjectData = page_data.project_data.get_ref()
		if project_data.pages.has(page_data.designation.get_string() + "_" + tree_item.get_text(0)):
			tree_item.set_text(0, page_data.name + " " + page_data.description)
		else:
			page_data.name = tree_item.get_text(0)
			tree_item.set_text(0, page_data.name + " " + page_data.description)
		return
	if metadata is ProjectData:
		pass


func _on_tree_gui_input(event: InputEvent) -> void:
	if event.is_action(&"rename") and event.is_pressed():
		_on_rename_triggered()


func _on_context_menu_index_pressed(index: int) -> void:
	var tree_item: TreeItem = tree.get_selected()
	match context_menu.get_item_text(index):
		"CREATE":
			var last_child: TreeItem = _get_last_child_of_selected_item(tree_item)
			var last_child_page_data: PageData
			if last_child.get_metadata(0) is PageData:
				last_child_page_data = last_child.get_metadata(0)
			new_page_dialog.activate(last_child_page_data)
		"OPEN":
			if tree_item.get_metadata(0) is PageData:
				open_page_requested.emit(tree_item.get_metadata(0))
		"CLOSE":
			if tree_item.get_metadata(0) is ProjectData:
				var project_data: ProjectData = tree_item.get_metadata(0)
				_close_project(project_data)
		"COPY":
			pass
		"PASTE":
			pass
		"RENAME":
			_on_rename_triggered()
		"NUMBERING":
			var pages_to_number: Array[PageData] = get_selected_pages(true)
			number_pages_dialog.activate(pages_to_number)
		"PROPERTIES":
			var pages_to_edit: Array[PageData] = get_selected_pages(true)
			page_properties_dialog.activate(pages_to_edit)


func _on_rename_triggered() -> void:
	var tree_item: TreeItem = tree.get_selected()
	if not tree_item:
		return
	if tree_item.get_metadata(0) is ProjectData:
		return
	tree_item.set_text(0, tree_item.get_text(0).split(" ")[0])
	tree.edit_selected(true)


func _get_last_child_of_selected_item(selected_item: TreeItem) -> TreeItem:
	var last_child: TreeItem
	if selected_item.get_metadata(0) is not PageData:
		if selected_item.get_child_count() == 0:
			return selected_item
		return _get_last_child_of_selected_item(selected_item.get_child(0))
	var parent_tree_item: TreeItem = selected_item.get_parent()
	var parent_child_count: int = parent_tree_item.get_child_count()
	last_child = parent_tree_item.get_child(parent_child_count - 1)
	return last_child


func _on_page_data_changed(page_tree_item: TreeItem) -> void:
	var page_data: PageData = page_tree_item.get_metadata(0)
	page_tree_item.set_icon(0, PageData.PAGE_TYPE_ICONS[page_data.type])
	page_tree_item.set_text(0, page_data.name + " " + page_data.description)


func _select_children_recursive(parent_item: TreeItem, list: Array[TreeItem]) -> void:
	var child: TreeItem = parent_item.get_first_child()
	while child:
		if not list.has(child):
			list.append(child)
		_select_children_recursive(child, list)
		child = child.get_next()


func _on_new_page_dialog_page_created(page_data: PageData) -> void:
	var selected_tree_item: TreeItem = tree.get_selected()
	var current_project: ProjectData = get_project_from_child(selected_tree_item)
	var parent_tree_item: TreeItem = selected_tree_item
	if selected_tree_item.get_metadata(0) is PageData:
		parent_tree_item = selected_tree_item.get_parent()
	add_page(parent_tree_item, page_data)
	current_project.add_page(page_data)
	create_page_requested.emit(page_data)


func _on_project_data_closed(project_data: ProjectData) -> void:
	project_data.closed.disconnect(_on_project_data_closed)
	var closed_project_tree_item: TreeItem
	for project_item: TreeItem in root.get_children():
		if not project_item.get_metadata(0) == project_data:
			continue
		closed_project_tree_item = project_item
		break
	if not closed_project_tree_item:
		return
	root.remove_child(closed_project_tree_item)
	closed_project_tree_item.free()


func _on_new_page_dialog_new_page_name_changed(new_name: String) -> void:
	var tree_item: TreeItem = tree.get_selected()
	var project_data: ProjectData = get_project_from_child(tree_item)
	if project_data.pages.has(new_page_dialog.designation_line_edit.text + "_" + new_name):
		new_page_dialog.get_ok_button().disabled = true
		new_page_dialog.name_line_edit.theme_type_variation = "LineEditWarning"
	else:
		new_page_dialog.get_ok_button().disabled = false
		new_page_dialog.name_line_edit.theme_type_variation = ""


func _close_project(project_data: ProjectData) -> void:
	close_project_requested.emit(project_data)
	for page_data: PageData in project_data.pages.values():
		page_data.name_changed.disconnect(project_data._on_page_data_name_changed)
