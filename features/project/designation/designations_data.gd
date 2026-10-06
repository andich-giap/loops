class_name DesignationsData
extends Resource


signal added(designation: Designation)
signal removed(designation: Designation)
signal designation_changed(designation: Designation)
@export var designations: Dictionary[Designation.Type, Array]


func _init(designation_string: String = "") -> void:
	## TODO implement construction from string
	pass
	#if not designations.is_empty():
		#return
	#for type: Designation.Type in Designation.Type.values():
		#designations[type] = []


func add_designation(designation: Designation) -> void:
	designations[designation.type].append(designation)
	added.emit(designation)
	emit_changed()
	designation.changed.connect(designation_changed.emit.bind(designation))
	designation.changed.connect(emit_changed)


func remove_designation(designation: Designation) -> void:
	if designation in designations[designation.type]:
		var index: int = designations[designation.type].find(designation)
		designations[designation.type].pop_at(index)
		removed.emit(designation)
		emit_changed()


func get_last_designation_tag() -> StringName:
	if designations.is_empty():
		return ""
	var designation_types_reversed: Array = Designation.Type.values()
	designation_types_reversed.reverse()
	for type: Designation.Type in designation_types_reversed:
		if designations[type].is_empty():
			continue
		var last_designation: Designation = designations[type].back()
		return Designation.designation_signs[last_designation.type] + last_designation.name
	return ""


func get_last_designation() -> Designation:
	if designations.is_empty():
		return null
	var designation_types_reversed: Array = Designation.Type.values()
	designation_types_reversed.reverse()
	for type: Designation.Type in designation_types_reversed:
		if designations[type].is_empty():
			continue
		return designations[type].back()
	return null


# TODO Get Designation as string
func get_string() -> StringName:
	return ""
