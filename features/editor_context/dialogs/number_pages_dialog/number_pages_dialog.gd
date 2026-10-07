class_name NumberPagesDialog
extends ConfirmationDialog
 ## Dialog that is used to number the selected pages and children of [Designation] tree items.


@onready var numbering_begin_spin_box: SpinBox = %NumberingBeginSpinBox ## Used for specifying starting page number.
@onready var step_size_spin_box: SpinBox = %StepSizeSpinBox ## Used for specifying page number step.
@onready var subpages_menu_button: MenuButton = %SubpagesMenuButton ## Used for specifying how to manage the subpages.


func _ready() -> void:
	canceled.connect(_on_cancel)
	subpages_menu_button.get_popup().index_pressed.connect(_handle_sub_pages_numbering_type_changed)


## Triggers the dialog to be shown.
func activate(pages: Array[PageData]) -> void:
	show()
	confirmed.connect(number_pages.bind(pages), CONNECT_ONE_SHOT)


## Used for numbering specified [param pages].
func number_pages(pages: Array[PageData]) -> void:
	var start_number: int = int(numbering_begin_spin_box.value)
	@warning_ignore_start("unused_variable")
	var current_number: int = start_number
	var step: int = int(step_size_spin_box.value)
	@warning_ignore_restore("unused_variable")
	for page: PageData in pages:
		if page.name.contains("."):
			pass
			# TODO Must implement after designations are added to the PageData
			# to handle numbering with accordance to the designation.


func _on_cancel() -> void:
	hide()
	confirmed.disconnect(number_pages)


func _handle_sub_pages_numbering_type_changed(index: int) -> void:
	subpages_menu_button.text = subpages_menu_button.get_popup().get_item_text(index)
	subpages_menu_button.icon = subpages_menu_button.get_popup().get_item_icon(index)
