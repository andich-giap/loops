extends Panel


@onready var ruler: Panel = %Ruler
@onready var ruler_length_spin_box: SpinBox = %RulerLengthSpinBox
@onready var ruler_length_h_slider: HSlider = %RulerLengthHSlider
@onready var reset_ruler_length_button: Button = %ResetRulerLengthButton
@onready var dpi_spin_box: SpinBox = %DPISpinBox


func _ready() -> void:
	ruler_length_spin_box.value = ruler.get(&"ruler_length")
	ruler_length_h_slider.value = ruler_length_spin_box.value
	dpi_spin_box.value = Units.dpi
	
	dpi_spin_box.value_changed.connect(_on_dpi_spin_box_value_changed)
	
	reset_ruler_length_button.pressed.connect(ruler_length_h_slider.set_value_no_signal.bind(ruler_length_h_slider.value))
	reset_ruler_length_button.pressed.connect(ruler_length_spin_box.set_value_no_signal.bind(ruler_length_h_slider.value))
	reset_ruler_length_button.pressed.connect(_on_ruler_length_h_slider_value_changed.bind(ruler_length_h_slider.value))
	
	ruler_length_spin_box.value_changed.connect(ruler_length_h_slider.set_value_no_signal)
	ruler_length_spin_box.value_changed.connect(_on_ruler_length_h_slider_value_changed)
	
	ruler_length_h_slider.value_changed.connect(ruler_length_spin_box.set_value_no_signal)
	ruler_length_h_slider.value_changed.connect(_on_ruler_length_h_slider_value_changed)


func _on_ruler_length_h_slider_value_changed(value: float) -> void:
	ruler.set(&"ruler_length", value)
	ruler.queue_redraw()


func _on_dpi_spin_box_value_changed(value: float) -> void:
	Units.dpi = int(value)
	ruler.queue_redraw()
