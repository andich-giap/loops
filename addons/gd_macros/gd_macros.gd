@tool
extends EditorPlugin


var script_menu_plugin: EditorContextMenuPlugin


func _enter_tree() -> void:
	script_menu_plugin = preload("uid://kpicvegf8u10").new()
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCRIPT_EDITOR_CODE, script_menu_plugin)


func _exit_tree() -> void:
	if script_menu_plugin:
		remove_context_menu_plugin(script_menu_plugin)
		script_menu_plugin = null
