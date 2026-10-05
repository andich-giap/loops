@tool
class_name Units


const DPI: int = 82
enum Mesurand {
	TEMPERATURE,
	PRESSURE,
	FLOW,
	PH,
}
enum Unit {
	PASCAL,
	CELCIUS,
	METER,
	METER_CUBED,
	KG,
}
static var mesurand_tag: Dictionary[Mesurand, String] = {
	Mesurand.TEMPERATURE: "T",
	Mesurand.PRESSURE: "P",
	Mesurand.FLOW: "F",
	Mesurand.PH: "A",
}


static func mm_to_px(mm: float) -> float:
	return mm / 25.4 * 82


static func px_to_mm(px: float) -> float:
	return px * 25.4 / 82
