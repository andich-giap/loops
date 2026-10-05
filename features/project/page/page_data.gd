@tool
class_name PageData
extends Resource


signal name_changed(new_name: StringName, old_name: StringName)
signal size_changed(size: Vector2)
signal grid_interval_changed(grid_interval: float)
enum Type {
	GRAPHICS,
	SCHEMATIC_SINGLE_LINE,
	SCHEMATIC_MULTI_LINE,
	PID,
	REPORT,
}
@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var size: Vector2 = Vector2(210.0, 297.0):
	set = set_size
@export var designation: DesignationsData
@export var name: StringName:
	set = set_page_name
@export var type: Type
@export var description: String
@export var contents: PackedScene
@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var grid_interval: float = 4.0:
	set = set_grid_interval
@export_storage var project_data: WeakRef
var is_saved: bool = false


func set_size(_size: Vector2) -> void:
	size = _size
	emit_changed()
	size_changed.emit(size)


func set_grid_interval(_grid_interval: float) -> void:
	grid_interval = max(0.01, _grid_interval)
	emit_changed()
	grid_interval_changed.emit(grid_interval)


func get_full_name() -> StringName:
	return "_".join([designation.get_string(), name])


func set_page_name(_name: StringName) -> void:
	var old_name: StringName = name
	name = _name
	name_changed.emit(name, old_name)
	emit_changed()
