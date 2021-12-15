extends PanelContainer


func _ready():
	var _error = $SettingsList/BackButton.connect("pressed", self, "_on_back_pressed")
	_error = connect("visibility_changed", self, "_on_visibility_changed")


func _on_back_pressed():
	get_parent().get_parent().get_node("BackSound").play()
	
	hide()


func _on_visibility_changed() -> void:
	if visible:
		$SettingsList/BackButton.grab_focus()
