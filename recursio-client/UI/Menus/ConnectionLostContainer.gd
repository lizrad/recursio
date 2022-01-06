 extends PanelContainer


onready var _back_button: SoundButton = get_node("ConnectionLostList/BackButton")

func _ready() -> void:
	var _error = _back_button.connect("pressed", self, "_on_back_button_pressed")
	_error = self.connect("visibility_changed", self, "_on_visibility_changed")


func _on_visibility_changed() -> void:
	if self.visible:
		_back_button.grab_focus()


func _on_back_button_pressed() -> void:
	hide()
