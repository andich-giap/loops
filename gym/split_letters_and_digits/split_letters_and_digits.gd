@tool
extends EditorScript


const DELIMITER: String = "-"


func _run() -> void:
	var delimited_values: Array[String]
	for value: String in values:
		var new_value: String = value
		for i: int in range(value.length()):
			if value[i].is_valid_int() and not value[i-1] == DELIMITER:
				new_value = value.replace(value[i], DELIMITER + value[i])
				break
		delimited_values.append(new_value)
	
	for value: String in delimited_values:
		print(value)


var values: Array[String] = [
	"MZSA3722",
	"MSA3731",
	"MSA3728",
	"MSA3729",
	"MSA3730",
	"MSA3721",
	"M3715",
	"MSA3714",
	"MSA3725",
	"MSA3754",
	"MSA3719",
	"MSA3724",
	"MSA3705",
	"MSA3713",
	"M3716",
	"MSA3702",
	"MSA3720",
	"Н-207/а",
]
