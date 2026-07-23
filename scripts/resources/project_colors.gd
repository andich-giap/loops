@tool
class_name ProjectColor


enum Debug {
	AREA,
	CURSOR,
}
enum Selection {
	AREA,
	DASH,
	LINE,
}
static var debug_values: Dictionary[Debug, Color] = {
	Debug.AREA: Color(0.0, 0.675, 0.69, 0.239),
	Debug.CURSOR: Color(0.0, 0.651, 0.208, 0.482),
}
static var selection_values: Dictionary[Selection, Color] = {
	Selection.AREA: Color(0.0, 0.675, 0.69, 0.239),
	Selection.DASH: Color(0.112, 0.484, 0.826, 0.314),
	Selection.LINE: Color(0.0, 0.439, 0.85, 1.0),
}
