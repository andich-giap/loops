@tool
class_name ProjectColor


const THEME: Theme = preload("uid://dmxt5luifu1kc")
const PROJECT_PALLETE: Pallete = preload("uid://b1s4dsfjjdjc")

enum Debug {
	AREA,
	CURSOR,
}
enum Selection {
	AREA,
	DASH,
	LINE,
	TEXT,
}
static var debug_values: Dictionary[Debug, Color] = {
	Debug.AREA: Color(0.0, 0.675, 0.69, 0.239),
	Debug.CURSOR: Color(0.0, 0.651, 0.208, 0.482),
}
static var selection_values: Dictionary[Selection, Color] = {
	Selection.AREA: Color(0.0, 0.675, 0.69, 0.239),
	Selection.DASH: Color(0.114, 0.482, 0.827, 0.314),
	Selection.LINE: Color(0.0, 0.439, 0.851, 1.0),
	Selection.TEXT: Color(0.0, 0.439, 0.85, 1.0),
}


static func setup() -> void:
	for color: Color in PROJECT_PALLETE.color_maps.keys():
		if not PROJECT_PALLETE.color_maps[color]:
			continue
		for pallete_map: PalleteMap in PROJECT_PALLETE.color_maps[color].pallete_maps:
			print(color)
			THEME.set_color(pallete_map.name, pallete_map.theme_type, color)
