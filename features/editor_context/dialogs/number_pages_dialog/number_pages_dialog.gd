class_name NumberPagesDialog
extends ConfirmationDialog


@onready var numbering_begin_spin_box: SpinBox = %NumberingBeginSpinBox
@onready var step_size_spin_box: SpinBox = %StepSizeSpinBox
@onready var subpages_menu_button: MenuButton = %SubpagesMenuButton


func _ready() -> void:
	canceled.connect(_on_cancel)
	subpages_menu_button.get_popup().index_pressed.connect(handle_sub_pages_numbering_type_changed)


func activate(pages: Array[PageData]) -> void:
	show()
	confirmed.connect(number_pages.bind(pages), CONNECT_ONE_SHOT)


func number_pages(pages: Array[PageData]) -> void:
	var start_number: int = numbering_begin_spin_box.value
	var current_number: int = start_number
	var step: int = step_size_spin_box.value
	for page: PageData in pages:
		if page.name.contains("."):
			pass
			# TODO Must implement after designations are added to the PageData
			# to handle numbering with accordance to the designation.


func _on_cancel() -> void:
	hide()
	confirmed.disconnect(number_pages)


func handle_sub_pages_numbering_type_changed(index: int) -> void:
	subpages_menu_button.text = subpages_menu_button.get_popup().get_item_text(index)
	subpages_menu_button.icon = subpages_menu_button.get_popup().get_item_icon(index)
