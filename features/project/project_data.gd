class_name ProjectData
extends Resource
## Contains all the data about project itself.


signal page_added(page_data: PageData) ## Emitted when a page is added to the project.
signal closed ## Emitted upon the closing of the project.
@export var name: StringName ## The name of the project.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_READ_ONLY) var last_edited: String ## The time at which the last edit was done.
@export var pages: Dictionary[StringName, PageData] ## Contains all the pages of the project. The key is a string representation of [DesignationsData].


## Adds a given [param page_data] to the project.
func add_page(page_data: PageData) -> void:
	var _resource_path: String = resource_path.get_basename() \
		+ "_loops_contents/pages/" \
		+ page_data.get_full_name() \
		+ ".tres"
	page_data.take_over_path(_resource_path)
	var save_error: Error = ResourceSaver.save(page_data)
	if not save_error == OK:
		printerr("Save error %s relative to path: %s" % [save_error, _resource_path])
	pages[page_data.designation.get_string() + "_" + page_data.name] = page_data
	page_data.project_data = weakref(self)
	page_added.emit(page_data)
	page_data.name_changed.connect(_on_page_data_name_changed.bind(page_data.name, page_data), CONNECT_PERSIST)
	ResourceSaver.save(self)


## Closes a project
func close() -> void:
	closed.emit()


func _on_page_data_name_changed(old_name: StringName, page_data: PageData) -> void:
	pages.erase(page_data.designation.get_string() + "_" + old_name)
	pages[page_data.designation.get_string() + "_" + page_data.name] = page_data
	var new_path: String = page_data.resource_path.get_base_dir() + "/" + page_data.get_full_name() + ".tres"
	DirAccess.rename_absolute(page_data.resource_path, new_path)
	page_data.take_over_path(new_path)
	ResourceSaver.save(self)
	page_data.name_changed.connect(_on_page_data_name_changed.bind(page_data.name, page_data), CONNECT_ONE_SHOT)
