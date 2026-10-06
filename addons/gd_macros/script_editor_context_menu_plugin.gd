extends EditorContextMenuPlugin


func _popup_menu(paths: PackedStringArray) -> void:
	var code_edit: CodeEdit = Engine.get_main_loop().root.get_node(paths[0])
	if not code_edit:
		return
	var selected_text = code_edit.get_selected_text().strip_edges()
	if selected_text.is_empty() or " " in selected_text:
		selected_text = code_edit.get_word_under_caret()
		if selected_text.is_empty() or " " in selected_text:
			return
	
	add_context_menu_item(
		"Create Function from Selection", 
		_on_create_function_pressed.bind(selected_text)
	)


func _on_create_function_pressed(code_edit: CodeEdit, selected_text: String) -> void:
	selected_text = selected_text.replace(".", "_")
	
	var new_function_template = "\n\nfunc %s() -> void:\n\tpass" % selected_text
	code_edit.deselect()
	
	var last_line = code_edit.get_line_count() - 1
	var last_line_length = code_edit.get_line(last_line).length()
	code_edit.insert_text("\n", last_line, last_line_length)
	code_edit.insert_line_at(last_line + 1, new_function_template)
