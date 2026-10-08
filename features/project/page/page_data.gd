@tool
class_name PageData
extends Resource
## Contains all the information and contents of the page.


signal designation_changed ## Emitted when [member designation] is changed.
signal name_changed ## Emitted when [member name] is changed.
signal description_changed ## Emitted when [member description] is changed.
signal size_changed(size: Vector2) ## Emitted when [member size] is changed.
signal grid_interval_changed(grid_interval: float) ## Emitted when [member grid_interval] is changed.
enum Type { ## Possible type of the page.
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
@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var size: Vector2 = Vector2(210.0, 297.0): ## The size of the page in millimetres.
	set = set_size
@export var designation: DesignationsData: ## The designation of the page in the project.
	set = set_designation
@export var name: StringName: ## The name of the page. Could be represented as 0, 3, 5.1, 10a.
	set = set_page_name
@export var type: Type ## The type of the page.
@export var description: String: ## The description of the page.
	set = set_description
@export var contents: PackedScene ## The graphical contents of the page that is displayed by [PageViewport].
@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var grid_interval: float = 4.0: ## The interval of the [Grid] in [PageViewport].
	set = set_grid_interval
@export_storage var project_data: WeakRef ## Reference to the [ProjectData].
var is_saved: bool = false ## Determines wether the page is changed and is it saved or not.


func _init(_name: StringName = &"1", _designation: DesignationsData = null) -> void:
	name = _name
	if not _designation:
		_designation = DesignationsData.new()
	designation = _designation


func set_size(_size: Vector2) -> void:
	size = _size
	emit_changed()
	size_changed.emit(size)


func set_grid_interval(_grid_interval: float) -> void:
	grid_interval = max(0.01, _grid_interval)
	emit_changed()
	grid_interval_changed.emit(grid_interval)


## Returns the string representation of the [member designation] followed by the [member name].
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
