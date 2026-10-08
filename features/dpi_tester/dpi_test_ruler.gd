extends Panel


@export_custom(PROPERTY_HINT_NONE, "suffix: mm") var ruler_length: float = 100


func _ready() -> void:
	custom_minimum_size.x = Units.mm_to_px(ruler_length)


func _draw() -> void:
	for i: int in range(ruler_length + 1):
		var line_length: float = 10
		if i % 5 == 0:
			line_length = 15
		if i % 10 == 0:
			line_length = 20
			var text_line: TextLine = TextLine.new()
			text_line.add_string(
				str(int(float(i) / 10)),
				get_theme_default_font(),
				get_theme_default_font_size()
			)
			text_line.alignment = HORIZONTAL_ALIGNMENT_CENTER
			text_line.draw(
				get_canvas_item(),
				Vector2(
					Units.mm_to_px(i) - text_line.get_line_width() / 2,
					-line_length
					),
				Color.BLACK
			)
		draw_line(
			Vector2(Units.mm_to_px(i), 0),
			Vector2(Units.mm_to_px(i), line_length),
			Color.BLACK,
		)
