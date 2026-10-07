@icon("res://addons/at-icons/control/bell.svg")
class_name Notification
extends PanelContainer
## Displays the notification for the events.


signal finished ## Emitted when the notification disappeares.
var _tween: Tween
var _property_tweener: PropertyTweener


func _ready() -> void:
	hide()


## Used for displaying a notification.
func trigger() -> void:
	if _tween:
		_tween.kill()
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	show()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	_property_tweener = _tween.tween_property(self, ^"modulate", Color.WHITE, 0.1)
	_tween.tween_await(get_tree().create_timer(1.0).timeout)
	_property_tweener = _tween.tween_property(self, ^"modulate", Color(1.0, 1.0, 1.0, 0.0), 0.3)
	_tween.finished.connect(_finish)


func _finish() -> void:
	finished.emit()
	hide()
	_tween.kill()
