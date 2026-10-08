extends GDUnitProjectTestSuite


func test_open_project() -> void:
	open_project(UNIT_TEST_PROJECT)
	assert_object(root_context_node.current_project).is_not_null()


func test_open_page() -> void:
	var page_data: PageData = PageData.new(str(UNIT_TEST_PROJECT.pages.size() + 1))
	var pages_count: int = UNIT_TEST_PROJECT.pages.size()
	UNIT_TEST_PROJECT.add_page(page_data)
	var new_pages_count: int = UNIT_TEST_PROJECT.pages.size()
	assert_int(new_pages_count).is_equal(pages_count + 1)


func test_delete_page() -> void:
	var pages_count: int = UNIT_TEST_PROJECT.pages.size()
	var page_data: PageData
	if UNIT_TEST_PROJECT.pages.is_empty():
		page_data = PageData.new(&"1")
		UNIT_TEST_PROJECT.add_page(page_data)
	else:
		page_data = UNIT_TEST_PROJECT.pages.values()[0]
	UNIT_TEST_PROJECT.delete_pages([page_data])
	var new_pages_count: int = UNIT_TEST_PROJECT.pages.size()
	assert_int(new_pages_count).is_equal(pages_count - 1)
