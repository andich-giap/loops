@tool
class_name Grid
extends PanelContainer


static var is_orthogonal: bool = false
static var color: Color = Color(0.76, 0.76, 0.76, 1.0)
static var width: float = 1.0
static var interval: float = 10.0:
	set = set_interval
const GRID_MATERIAL: ShaderMaterial = preload("uid://csvrt4x5w11m0")
var shader_material: ShaderMaterial


func _init() -> void:
	theme_type_variation = &"Grid"
	resized.connect(_on_resized)
	material = GRID_MATERIAL
	shader_material = material
	shader_material.set_shader_parameter(&"Size", size)
	shader_material.set_shader_parameter(&"Interval", Units.mm_to_px(interval))


func _ready() -> void:
	shader_material.set_shader_parameter(&"Color", get_theme_color(&"grid_color"))


func _on_resized() -> void:
	shader_material.set_shader_parameter(&"Size", size)


func set_interval(_interval: float) -> void:
	interval = _interval
	shader_material.set_shader_parameter(&"Interval", Units.mm_to_px(interval))
