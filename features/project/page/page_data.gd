@tool
class_name PageData
extends Resource


signal designation_changed
signal name_changed
signal description_changed
signal size_changed(size: Vector2)
signal grid_interval_changed(grid_interval: float)
enum Type {
	GRAPHICS,
	SCHEMATIC_SINGLE_LINE,
	SCHEMATIC_MULTI_LINE,
	PID,
	REPORT,
}
const PAGE_TYPE_ICONS: Dictionary[Type, Texture2D] = {
	Type.GRAPHICS: preload("uid://r801gyeki358"),
	Type.SCHEMATIC_SINGLE_LINE: preload("uid://k86ux30n4nnq"),
	Type.SCHEMATIC_MULTI_LINE: preload("uid://bgxgbadvlil6i"),
	Type.PID: preload("uid://bidskrrhvig8f"),
	Type.REPORT: preload("uid://d4jbno55cv12g"),
}
@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var size: Vector2 = Vector2(210.0, 297.0):
	set = set_size
@export var designation: DesignationsData:
	set = set_designation
@export var name: StringName:
	set = set_page_name
@export var type: Type
@export var description: String:
	set = set_description
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


func set_designation(_designation: DesignationsData) -> void:
	designation = _designation
	designation_changed.emit()
	emit_changed()


func set_description(_description: String) -> void:
	description = _description
	description_changed.emit()
	emit_changed()
