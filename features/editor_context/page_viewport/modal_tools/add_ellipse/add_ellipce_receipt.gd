class_name AddEllipseReceipt
extends ModalToolReceipt


var ellipse: Ellipse


func _init(_ellipse: Ellipse) -> void:
	ellipse = _ellipse


func apply_changes(page_viewport: PageViewport) -> void:
	ellipse.request_ready()
	page_viewport.add_graphics(ellipse)
	ellipse.changed.emit()
