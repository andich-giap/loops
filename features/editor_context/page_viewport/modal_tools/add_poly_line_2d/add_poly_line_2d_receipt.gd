class_name AddPolyLine2DReceipt
extends ModalToolReceipt


var poly_line_2d: PolyLine2D


func _init(_poly_line_2d: PolyLine2D) -> void:
	poly_line_2d = _poly_line_2d


func apply_changes(page_viewport: PageViewport) -> void:
	poly_line_2d.request_ready()
	page_viewport.add_graphics(poly_line_2d)
	poly_line_2d.changed.emit()
