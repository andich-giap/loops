@tool
extends EditorPlugin


const EDITOR_ICONS_THEME_TYPE: StringName = &"EditorIcons"
const SAVE_PATH: String = "res://resources/icons"
var dock: EditorDock


func _enter_tree() -> void:
	var editor_theme: Theme = EditorInterface.get_editor_theme()
	dock = EditorDock.new()
	dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_UL
	
	
	var scroll_container: ScrollContainer = ScrollContainer.new()
	scroll_container.name = &"Editor Icons"
	dock.add_child(scroll_container)
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var h_flow_container: HFlowContainer = HFlowContainer.new()
	h_flow_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_flow_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(h_flow_container)
	
	for icon: StringName in editor_theme.get_icon_list(EDITOR_ICONS_THEME_TYPE):
		var button: Button = Button.new()
		button.icon = editor_theme.get_icon(icon, EDITOR_ICONS_THEME_TYPE)
		button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override(&"icon_max_width", 64)
		button.tooltip_text = icon
		button.pressed.connect(_on_icon_pressed.bind(icon, button.icon))
		h_flow_container.add_child(button)
	
	add_dock(dock)


func _exit_tree() -> void:
	remove_dock(dock)
	dock.queue_free()


func _on_icon_pressed(name: StringName, icon: Texture2D) -> void:
	ResourceSaver.save(icon, SAVE_PATH.path_join(name.to_snake_case() + ".res"))
