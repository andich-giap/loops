@tool
class_name AlarmSafetyData
extends Resource


enum Setpoint {
	EMERGENCY_MAXIMUM,
	MAXIMUM,
	SUBMAXIMUM,
	NORMAL,
	SUBMINIMUM,
	MINIMUM,
	EMERGENCY_MINIMUM,
}
@export var setpoint: Setpoint
@export var value: float
@export var unit_override: Units.Unit
