@tool
extends EditorScript


const DELIMITER: String = "-"


func _run() -> void:
	var delimited_values: Array[String]
	for value: String in values:
		delimited_values.append(delimit_string(value))
	for value: String in delimited_values:
		print(value)


func delimit_string(string: String) -> String:
	var new_string: String = string
	for i: int in range(string.length()):
		if string[i].is_valid_int() and not string[i-1] == DELIMITER:
			var split_string: PackedStringArray = string.split(string[i])
			split_string[0] = split_string[0] + DELIMITER
			new_string = string[i].join(split_string)
			break
	return new_string


var values: Array[String] = [
	"MSA3745",
	"LV361",
	"HC3845",
	"MSA3709",
	"HC3848",
	"HC3847",
	"H-231/1",
	"H-231/a",
	"HC3855",
	"HC3856",
	"MSA3711",
	"MSA3712",
	"MSA3737",
	"MSA3738",
	"HC3897",
	"HC3832",
	"HC3802",
	"HC3801",
	"HC3830",
	"HC3829",
	"MSA3701",
	"HC234/2",
	"HC3826",
	"HC914",
	"MSA3706",
	"MSA211/1",
	"MSA322/a",
	"MSA3753",
	"TV505",
	"HC3811",
	"MSA3756",
	"MSA3757",
	"HC2813",
	"HC2814",
	"HC2815",
	"HC2816",
	"HC3839",
	"HC3866",
	"HC3868",
	"HC3867",
	"Н-1/2",
	"HC3870",
	"HC3869",
	"MSA2707",
	"HC3810",
	"HS2831",
	"H-205/2",
	"HS2846",
	"HC2827",
	"HS2830",
	"HS2829",
	"HC3814",
	"HC1227",
	"HC907",
	"HC3849",
	"HC3838",
	"HC3863",
	"HC851",
	"HC1001",
	"HC852",
	"HC3840",
	"HC3850",
	"Н-105/1",
	"Н-105/1",
	"HC3851",
	"HC275",
	"HC274",
	"HC2818",
	"HC2838",
	"HC2840",
	"HC2839",
	"HC3874",
	"HC842",
	"HC12",
	"HC841",
	"HC11",
	"HC10",
	"MSA3717",
	"HC3834",
	"HSA111/1",
	"HSA111/a",
	"HS3846",
	"Н-1/1",
	"Н-1/1",
	"HC11",
	"MSA3723",
	"H-205/3",
	"MSA3710",
	"M3755",
	"MSA3718",
	"MSA3746",
	"HC1",
	"Н-207/1",
	"HC2806",
	"HC2805",
	"HC2843",
	"HC2837",
]
