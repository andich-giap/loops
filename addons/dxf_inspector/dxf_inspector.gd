@tool
class_name DXFPlugin
extends EditorPlugin


const DXF_INSPECTOR: PackedScene = preload("uid://bj3pyd453gwlr")
var dxf_inspector: DXFInspector


func _enable_plugin() -> void:
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	_init_main_scene()
	_make_visible(false)
	#for icon_name: StringName in EditorInterface.get_editor_theme().get_icon_list("EditorIcons"):
		#var icon: Texture2D = EditorInterface.get_editor_theme().get_icon(icon_name, "EditorIcons")
		#dxf_inspector.add_icon(icon, icon_name)


func _exit_tree() -> void:
	if dxf_inspector:
		dxf_inspector.queue_free()


func _has_main_screen():
	return true


func _get_plugin_name():
	return "DXF Inspector"


func _get_plugin_icon():
	return get_editor_icon("FileAccess")


func _make_visible(visible):
	if dxf_inspector:
		dxf_inspector.visible = visible


func _init_main_scene() -> void:
	dxf_inspector = DXF_INSPECTOR.instantiate()
	EditorInterface.get_editor_main_screen().add_child(dxf_inspector)
	dxf_inspector.reload_button.pressed.connect(_reload_main_scene)


func _reload_main_scene() -> void:
	dxf_inspector.queue_free()
	_init_main_scene()


static func get_editor_icon(icon_name: StringName) -> Texture2D:
	var icon: Texture2D
	if not Engine.is_editor_hint():
		return ResourceLoader.load("res://addons/editor_icons/%s.tres" % icon_name)
	icon = EditorInterface.get_editor_theme().get_icon(icon_name, "EditorIcons")
	#ResourceSaver.save(icon, "res://addons/editor_icons/%s.tres" % icon_name)
	return icon
