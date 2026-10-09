class_name SelectionQuery
extends RefCounted


enum Type {
	POINT,
	NODE,
	NODES,
}
var type: Type = Type.NODES


func _init(_type: Type) -> void:
	type = _type
