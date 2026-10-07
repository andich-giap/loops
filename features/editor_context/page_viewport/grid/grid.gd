@tool
class_name Grid
extends PanelContainer
## A Panel that is shows a grid pattern


static var is_orthogonal: bool = false ## Determines if the orthogonal logic of the placement of the graphics is applied by the [PageViewport].
static var interval: float = 10.0: ## Interval between grid points in millimetres.
	set = set_interval
const GRID_MATERIAL: ShaderMaterial = preload("uid://csvrt4x5w11m0")
var _shader_material: ShaderMaterial


func _init() -> void:
	theme_type_variation = &"Grid"
	resized.connect(_on_resized)
	material = GRID_MATERIAL
	_shader_material = material
	_shader_material.set_shader_parameter(&"Size", size)
	_shader_material.set_shader_parameter(&"Interval", Units.mm_to_px(interval))


func _ready() -> void:
	_shader_material.set_shader_parameter(&"Color", get_theme_color(&"grid_color"))


func _on_resized() -> void:
	_shader_material.set_shader_parameter(&"Size", size)


func set_interval(_interval: float) -> void:
	interval = _interval
	_shader_material.set_shader_parameter(&"Interval", Units.mm_to_px(interval))
