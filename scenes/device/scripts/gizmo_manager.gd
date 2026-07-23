@tool
class_name GizmoManager
extends Node2D


var gizmos: Array[Gizmo]


func _ready() -> void:
	for child: Node in get_children():
		if child is not Gizmo:
			return
		var gizmo: Gizmo = child
		gizmos.append(gizmo)


func show_gizmos() -> void:
	for child: Node in get_children():
		if child is not Gizmo:
			return
		var gizmo: Gizmo = child
		gizmo.visible = true


func hide_gizmos() -> void:
	for child: Node in get_children():
		if child is not Gizmo:
			return
		var gizmo: Gizmo = child
		gizmo.visible = false
