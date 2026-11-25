class_name AddEllipseModalTool
extends ModalTool


enum State {
	STARTING,
	WAITING_FOR_POINT,
	WAITING_FOR_MINOR_RADIUS,
	WAITING_FOR_MAJOR_RADIUS,
	EXECUTING,
	FINISHING,
}
var ellipse: Ellipse
var current_state: State = State.STARTING


func enter(__target_nodes: Array[Node], preview_layer: CanvasLayer) -> void:
	ellipse = Ellipse.new()
	_preview_layer = preview_layer
	_preview_layer.add_child(ellipse)
	request_place_position.emit()
	current_state = State.WAITING_FOR_POINT


func handle_input(event: InputEvent) -> void:
	if not [
		State.WAITING_FOR_POINT,
		State.WAITING_FOR_MINOR_RADIUS,
		State.WAITING_FOR_MAJOR_RADIUS,
	].has(current_state):
		return
	
	var place_position: Vector2 = _page_viewport.get_snapped_position().snapped_position_canvas_space
	
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT \
			and mouse_button_event.is_released():
			
			if current_state == State.WAITING_FOR_POINT:
				ellipse.position = place_position
				ellipse.queue_redraw()
				current_state = State.WAITING_FOR_MINOR_RADIUS
			
			elif current_state == State.WAITING_FOR_MINOR_RADIUS:
				var radius: float = ellipse.position.distance_to(place_position)
				radius = Units.px_to_mm(radius)
				ellipse.minor = radius
				ellipse.major = radius
				ellipse.queue_redraw()
				current_state = State.WAITING_FOR_MAJOR_RADIUS
			
			elif current_state == State.WAITING_FOR_MAJOR_RADIUS:
				var radius: float = ellipse.position.distance_to(place_position)
				radius = Units.px_to_mm(radius)
				ellipse.major = radius
				ellipse.queue_redraw()
				current_state = State.EXECUTING
				execute()
			
			return
	
	if event is InputEventMouseMotion:
		if current_state == State.WAITING_FOR_POINT:
			ellipse.position = place_position
			ellipse.queue_redraw()
		elif current_state == State.WAITING_FOR_MINOR_RADIUS:
			var radius: float = ellipse.position.distance_to(place_position)
			radius = Units.px_to_mm(radius)
			ellipse.minor = radius
			ellipse.major = radius
			ellipse.queue_redraw()
		elif current_state == State.WAITING_FOR_MAJOR_RADIUS:
			var radius: float = ellipse.position.distance_to(place_position)
			radius = Units.px_to_mm(radius)
			ellipse.major = radius
			ellipse.queue_redraw()


func execute() -> void:
	var add_ellipse_receipt: AddEllipseReceipt = AddEllipseReceipt.new(ellipse)
	current_state = State.FINISHING
	exit(add_ellipse_receipt)


func exit(receipt: ModalToolReceipt) -> void:
	_preview_layer.remove_child(ellipse)
	finished.emit(receipt)


func deactivate_modal_tool() -> void:
	if not current_state == State.FINISHING:
		ellipse.queue_free()
