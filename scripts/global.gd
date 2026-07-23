extends Node


var program_state: ProgramState


func _ready() -> void:
	var dir_access: DirAccess = DirAccess.open("user://")
	if not dir_access.dir_exists("Loops"):
		dir_access.make_dir("Loops")
	dir_access = DirAccess.open(dir_access.get_current_dir() + "/Loops")
	if not dir_access.file_exists("program_state.tres"):
		program_state = ProgramState.new()
		program_state.resource_path = dir_access.get_current_dir()+"/program_state.tres"
		ResourceSaver.save(program_state)
	else:
		program_state = ResourceLoader.load("user://Loops/program_state.tres")
