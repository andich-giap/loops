@tool
extends Line2D


@export var delta: float = 1.0:
	set = set_delta
@export var joints: Geometry2D.PolyJoinType = Geometry2D.PolyJoinType.JOIN_SQUARE:
	set = set_joints
@export var ends: Geometry2D.PolyEndType = Geometry2D.PolyEndType.END_BUTT:
	set = set_ends


func _ready() -> void:
	default_color = Color.TRANSPARENT


func _draw() -> void:
	draw_polyline(
		points,
		Color.WHITE,
		width
	)
	
	var offset_polylines: Array[PackedVector2Array] = Geometry2D.offset_polyline(
			points,
			delta,
			joints,
			ends
		)
	for offset_polyline: PackedVector2Array in offset_polylines:
		draw_polyline(
			offset_polyline,
			Color.RED,
			width,
		)
		
		for point: Vector2 in offset_polyline:
			draw_circle(
				point,
				width,
				Color.BLUE
			)

func set_delta(_delta: float) -> void:
	delta = _delta
	queue_redraw()


func set_joints(_joints: Geometry2D.PolyJoinType) -> void:
	joints = _joints
	queue_redraw()


func set_ends(_ends: Geometry2D.PolyEndType) -> void:
	ends = _ends
	queue_redraw()
