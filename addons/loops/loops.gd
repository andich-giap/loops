@tool
extends EditorPlugin


const LOOPS_MAIN: PackedScene = preload("uid://q4ood0wh1d5b")
var loops_main_instance: Node


func _enable_plugin() -> void:
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	loops_main_instance = LOOPS_MAIN.instantiate()
	EditorInterface.get_editor_main_screen().add_child(loops_main_instance)
	_make_visible(false)


func _exit_tree() -> void:
	if loops_main_instance:
		loops_main_instance.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible):
	if loops_main_instance:
		loops_main_instance.visible = visible


func _get_plugin_name():
	return "Loops"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
