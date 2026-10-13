class_name SelectionQuery
extends RefCounted
## A query for requesting a selection from [SelectionManager].


enum Type { ## Type of requested selection.
	POINT, ## Individual points of [PolyLine2D] or origin of [LLineEdit].
	NODE, ## A single node.
	NODES, ## Multiple nodes.
}
enum Mode { ## The mode for the selection. Determines how it will be processed after user chooses the selection.
	ADD, ## Adds selection to the current one.
	REPLACE, ## Replaces selection.
	SUBTRACT ## Subtracts the selection from the current one.
}
var type: Type = Type.NODES ## Type of selection.
var mode: Mode = Mode.REPLACE ## Mode of selection.


func _init(_type: Type = Type.NODES, _mode: Mode = Mode.REPLACE) -> void:
	type = _type
	mode = _mode
