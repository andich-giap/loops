@icon("res://addons/at-icons/control/bell.svg")
class_name Notification
extends PanelContainer


signal finished
var tween: Tween
var property_tweener: PropertyTweener


func _ready() -> void:
	hide()


func trigger() -> void:
	if tween:
		tween.kill()
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	show()
	tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	property_tweener = tween.tween_property(self, ^"modulate", Color.WHITE, 0.1)
	tween.tween_await(get_tree().create_timer(1.0).timeout)
	property_tweener = tween.tween_property(self, ^"modulate", Color(1.0, 1.0, 1.0, 0.0), 0.3)
	tween.finished.connect(finish)


func finish() -> void:
	finished.emit()
	hide()
	tween.kill()
	
