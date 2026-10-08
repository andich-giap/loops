class_name CreateProjectDialog
extends ConfirmationDialog
## A [ConfirmationDialog] for creating a project.


signal create_project_requested(project_name: String, project_path: String) ## Emitted on accepting the dialog.
@onready var name_line_edit: LineEdit = %NameLineEdit ## A [LineEdit] for filling in the project name.
@onready var path_line_edit: LineEdit = %PathLineEdit ## A [LineEdit] for filling in the project path.


func _ready() -> void:
	confirmed.connect(_create_project)
	canceled.connect(_on_canceled)


func _create_project() -> void:
	visible = false
	var project_name: String = name_line_edit.text.replace("/", "_")
	var project_path: String = path_line_edit.text + "/" + name_line_edit.text + ".tres"
	if project_name.is_empty():
		return
	if not DirAccess.dir_exists_absolute(project_path.get_base_dir()):
		## TODO Add warning notification for invalid path.
		return
	create_project_requested.emit(project_name, project_path)


func _on_canceled() -> void:
	visible = false
