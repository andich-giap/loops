class_name PageViewportContextMenu
extends PopupMenu


const GRAPHICS_SELECTED_ITEMS: Array[String] = [
	"COPY",
	"CUT",
	"PASTE",
	"separator",
	"MOVE",
	"DUPLICATE",
	"separator",
	"DELETE",
	"separator",
	"PROPERTIES",
]
const NO_SELECTION_ITEMS: Array[String] = [
	"PASTE",
]
const ITEM_ICONS: Dictionary[StringName, Texture2D] = {
	"COPY": preload("uid://dxbq48xios54n"),
	"CUT": preload("uid://co2dbg267dnnc"),
	"PASTE": preload("uid://b6wskrflnwf02"),
	"MOVE": preload("uid://capbagnwe8jn3"),
	"DUPLICATE": preload("uid://td175caftmhw"),
	"DELETE": preload("uid://cise7ijyppxmj"),
	"PROPERTIES": preload("uid://c3p6orknwcka8"),
}


func show_items(items: Array[String]) -> void:
	clear(true)
	size = Vector2.ZERO
	for item: String in items:
		if item == "separator":
			add_separator()
			continue
		add_icon_item(ITEM_ICONS[item], item)
