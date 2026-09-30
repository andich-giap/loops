class_name CreateProjectDialog
extends ConfirmationDialog


signal create_project_requested(project_namee: String, project_path: String)
@onready var name_line_edit: LineEdit = %NameLineEdit
@onready var path_line_edit: LineEdit = %PathLineEdit


func _ready() -> void:
	confirmed.connect(create_project)
	canceled.connect(_on_canceled)


func create_project() -> void:
	visible = false
	var project_name: String = name_line_edit.text.replace("/", "_")
	var project_path: String = path_line_edit.text + "/" + name_line_edit.text + ".tres"
	create_project_requested.emit(project_name, project_path)


func _on_canceled() -> void:
	visible = false
