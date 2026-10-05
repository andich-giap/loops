@tool
class_name Designation
extends Resource


enum Type {
	FUNCTIONAL_ASSIGNMENT, #==
	HIGHER_LEVEL_FUNCTION, #=
	INSTALLATION_SITE, #++
	MOUNTING_LOCATION, #+
	DOCUMENT_TYPE, #&
	USER_DEFINED, ##
}
@export var type: Type = Type.FUNCTIONAL_ASSIGNMENT:
	set = set_type
@export var name: StringName:
	set = set_designatoin_name
@export_multiline() var description: String = "":
	set = set_desription
static var designation_signs: Dictionary[Type, StringName] = {
	Type.FUNCTIONAL_ASSIGNMENT: &"==",
	Type.HIGHER_LEVEL_FUNCTION: &"=",
	Type.INSTALLATION_SITE: &"++",
	Type.MOUNTING_LOCATION: &"+",
	Type.DOCUMENT_TYPE: &"&",
	Type.USER_DEFINED: &"#",
}
static var designation_descriptions: Dictionary[Type, String] = {
	Type.FUNCTIONAL_ASSIGNMENT: "Функциональное присвоение",
	Type.HIGHER_LEVEL_FUNCTION: "Установка",
	Type.INSTALLATION_SITE: "Место сборки",
	Type.MOUNTING_LOCATION: "Место установки",
	Type.DOCUMENT_TYPE: "Тип документа",
	Type.USER_DEFINED: "Определено пользователем",
}

static func get_type_by_sign(_sign: StringName) -> Type:
	for _type: Type in Type.values():
		if designation_signs[_type] == _sign:
			return _type
	@warning_ignore("int_as_enum_without_match")
	return -1 as Type


func set_type(_type: Type) -> void:
	type = _type
	emit_changed()


func set_designatoin_name(_name: StringName) -> void:
	name = _name
	emit_changed()


func set_desription(_description: String) -> void:
	description = _description
	emit_changed()
