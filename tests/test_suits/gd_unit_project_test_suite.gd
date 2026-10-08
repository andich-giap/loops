class_name GDUnitProjectTestSuite
extends GdUnitTestSuite


const ROOT_CONTEXT: PackedScene = preload("uid://3vplj1htyh6")
const UNIT_TEST_PROJECT: ProjectData = preload("res://tests/project_data/unit_test_project/unit_test_project.tres")
var root_context_node: RootContext


func before() -> void:
	load_root_context()


func open_project(project_data: ProjectData) -> void:
	if not root_context_node:
		return
	root_context_node.open_project(project_data)


func load_root_context() -> void:
	root_context_node = ROOT_CONTEXT.instantiate()
	add_child(root_context_node)
	auto_free(root_context_node)
