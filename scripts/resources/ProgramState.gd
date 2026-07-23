class_name ProgramState
extends Resource


@export var opened_projects: Array[ProjectData] = []
@export var last_page_opened_project: ProjectData
@export var last_opened_page: PageData:
	set = set_last_opened_page,
	get = get_last_opened_page


func set_last_opened_page(_last_opened_page: PageData) -> void:
	if opened_projects.is_empty():
		return
	last_opened_page = _last_opened_page
	last_page_opened_project = last_opened_page.project_data.get_ref()
	ResourceSaver.save(last_opened_page)


func get_last_opened_page() -> PageData:
	if opened_projects.is_empty():
		return null
	if last_opened_page and last_page_opened_project:
		last_opened_page.project_data = weakref(last_page_opened_project)
	return last_opened_page
