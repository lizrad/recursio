 extends PanelContainer


onready var _back_button: SoundButton = get_node("ConnectionLostList/BackButton")

func _ready() -> void:
	var _error = _back_button.connect("pressed", self, "_on_back_button_pressed")

func _on_back_button_pressed() -> void:
	hide()
