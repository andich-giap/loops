class_name CreateProjectDialog
extends ConfirmationDialog


signal project_created(project_data: ProjectData)
@onready var name_line_edit: LineEdit = %NameLineEdit
@onready var path_line_edit: LineEdit = %PathLineEdit


func _ready() -> void:
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)


func _on_confirmed() -> void:
	visible = false
	var project_data: ProjectData = ProjectData.new()
	project_data.name = name_line_edit.text.replace("/", "_")
	project_data.resource_path = path_line_edit.text + "/" + name_line_edit.text + ".tres"
	ResourceSaver.save(project_data)
	project_created.emit(project_data)
	DirAccess.make_dir_absolute(project_data.resource_path.get_basename()+"_loops_contents")
	_create_contents_directories(project_data.resource_path.get_basename()+"_loops_contents")


func _on_canceled() -> void:
	visible = false


func _create_contents_directories(project_base_name: String) -> void:
	DirAccess.make_dir_absolute(project_base_name+"/pages")
