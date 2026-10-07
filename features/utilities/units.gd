@tool
class_name Units
## A static class that provides utility methods and keys to convert units of mesurements.


enum Mesurand { ## The parameter of the mesurement.
	TEMPERATURE,
	PRESSURE,
	FLOW,
	PH,
}
enum Unit { ## The unit of the parameter.
	PASCAL,
	CELCIUS,
	METER,
	METER_CUBED,
	KG,
}
static var dpi: int = 82 ## Users monitor dpi, used for [method mm_to_px] and [method px_to_mm] methods to work properly.
static var mesurand_tag: Dictionary[Mesurand, String] = { ## The instrument and loop tag that corresponds to the [enum Mesurand].
	Mesurand.TEMPERATURE: "T",
	Mesurand.PRESSURE: "P",
	Mesurand.FLOW: "F",
	Mesurand.PH: "A",
}


## Converts millimetres to pixels takin into accout [member dpi].
static func mm_to_px(mm: float) -> float:
	return mm / 25.4 * dpi


## Converts pixels to millimetres takin into accout [member dpi].
static func px_to_mm(px: float) -> float:
	return px * 25.4 / dpi
