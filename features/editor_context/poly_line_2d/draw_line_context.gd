@tool
class_name DrawLineContext
extends RefCounted


var canvas_item: CanvasItem ## Only [code]draw_*[/code] methods are safe to call on this.
var color: Color = Color.BLACK ## Line color.
var width: float = -1.0 ## Width in px. [code]-1.0[/code] means "unset"; the line always sets it.
var size_multiplier: float = 1.0 ## Unitless multiplier applied by each decoration to its [member LineDecoration.base_size].
