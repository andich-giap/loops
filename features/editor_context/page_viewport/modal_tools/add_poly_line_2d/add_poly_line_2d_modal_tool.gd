class_name AddPolyLine2DModalTool
extends ModalTool


enum State {
	STARTING,
	WAITING_FOR_POINT,
	EXECUTING,
	FINISHING,
}
var poly_line_2d: PolyLine2D
var current_state: State = State.STARTING


func enter(__target_nodes: Array[Node], preview_layer: CanvasLayer) -> void:
	poly_line_2d = PolyLine2D.new()
	poly_line_2d.add_point(Vector2.ZERO)
	_preview_layer = preview_layer
	_preview_layer.add_child(poly_line_2d)
	request_place_position.emit()
	current_state = State.WAITING_FOR_POINT


func handle_input(event: InputEvent) -> void:
	if not current_state == State.WAITING_FOR_POINT:
		return
	
	var last_point: int = poly_line_2d.points.size() - 1
	var place_position: Vector2 = _page_viewport.get_snapped_position().snapped_position_canvas_space
	
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		
		if mouse_button_event.button_index == MOUSE_BUTTON_RIGHT \
			and mouse_button_event.is_released():
			current_state = State.EXECUTING
			execute()
			return
		
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT \
			and mouse_button_event.is_released():
			poly_line_2d.set_point_position(last_point, place_position)
			poly_line_2d.add_point(place_position)
			return
	
	if event is InputEventMouseMotion:
		poly_line_2d.set_point_position(last_point, place_position)
	
	#if event is InputEventMouseMotion:
		#poly_line_2d._check_for_closest_point_to_cursor()
		#if _active_point >= 0 and points.size() > 0:
			#var place_position: Vector2 = _page_viewport.get_snapped_position().snapped_position_canvas_space
			#set_point_position(_active_point, place_position)
		#queue_redraw()
	#
	#if event is InputEventMouseButton:
		#var mouse_button_event: InputEventMouseButton = event
		#if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.is_released():
			#var place_position: Vector2 = _page_viewport.get_snapped_position().snapped_position_canvas_space
			#_previous_point_position = place_position
			#if points.size() == 0:
				#add_point(place_position)
			#add_point(place_position)
			#var last_index: int = get_point_count() - 1
			#set_point_position(last_index, place_position)
			#last_index = get_point_count() - 1
			#_active_point = last_index
			#queue_redraw()
			#
			## Set bounding_box
			#update_bounding_box()
		#
		#if mouse_button_event.button_index == MOUSE_BUTTON_RIGHT \
			#and mouse_button_event.is_released():
			#stop_drawing()
		#if ((event.is_action(&"zoom_in")
			#or event.is_action(&"zoom_out"))
			#and not _active_point == -1):
			#var place_position: Vector2 = _get_place_position()
			#set_point_position(_active_point, place_position)
	#
	#if is_active and event.is_action(&"ui_cancel"):
		#stop_drawing()
	
	
	
	
	
	
	#if event is InputEventMouseMotion:
		#poly_line_2d.position = _page_viewport.get_snapped_position().snapped_position
	#if event is InputEventMouseButton:
		#var mouse_button_event: InputEventMouseButton = event
		#if mouse_button_event.is_released() \
			#and mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			#poly_line_2d.position = _page_viewport.get_snapped_position().snapped_position
			#current_state = State.EXECUTING
			#execute()


func execute() -> void:
	poly_line_2d.remove_point(poly_line_2d.points.size() - 1)
	var add_poly_line_2d_receipt: AddPolyLine2DReceipt = AddPolyLine2DReceipt.new(poly_line_2d)
	current_state = State.FINISHING
	exit(add_poly_line_2d_receipt)


func exit(receipt: ModalToolReceipt) -> void:
	_preview_layer.remove_child(poly_line_2d)
	finished.emit(receipt)


func deactivate_modal_tool() -> void:
	if not current_state == State.FINISHING:
		poly_line_2d.queue_free()
