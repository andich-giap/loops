class_name SnappingPreview
extends Control


var current_receipt: SnapReceipt


func _ready() -> void:
	add_to_group(&"upadate_on_viewport_zoom")


func update(receipt: SnapReceipt) -> void:
	current_receipt = receipt
	queue_redraw()


func clear() -> void:
	current_receipt = null
	queue_redraw()


func _draw() -> void:
	if not current_receipt or not current_receipt.snap_successful:
		return
	
	var glyph_size: float = 6.0 / get_viewport_transform().x.length()
	var snapped_position: Vector2 = current_receipt.snapped_position_canvas_space
	var draw_color: Color = Color.RED
	var width: float = 2.0 / get_viewport_transform().x.length()
	
	match current_receipt.snap_type:
		SnapConstraint.Type.NONE:
			pass
		
		SnapConstraint.Type.GRID:
			# Plus sign
			draw_line(
				snapped_position + Vector2(-glyph_size, 0),
				snapped_position + Vector2(glyph_size, 0),
				draw_color,
				width
			)
			draw_line(
				snapped_position + Vector2(0, -glyph_size),
				snapped_position + Vector2(0, glyph_size),
				draw_color,
				width
			)
		
		SnapConstraint.Type.VERTEX:
			# Square
			var rect: Rect2 = Rect2(
				snapped_position - Vector2(glyph_size, glyph_size),
				Vector2(glyph_size, glyph_size) * 2.0
			)
			draw_rect(rect, draw_color, false, width)
		
		SnapConstraint.Type.MIDPOINT:
			# Triangle
			var p1: Vector2 = snapped_position + Vector2(0, -glyph_size)
			var p2: Vector2 = snapped_position + Vector2(glyph_size, glyph_size)
			var p3: Vector2 = snapped_position + Vector2(-glyph_size, glyph_size)
			draw_polyline(PackedVector2Array([p1, p2, p3, p1]), draw_color, width)


func _on_viewport_zoom_changed() -> void:
	queue_redraw()
