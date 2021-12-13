extends PanelContainer


func _ready():
	$SettingsList/BackButton.connect("pressed", self, "_on_back_pressed")


func _on_back_pressed():
	get_parent().get_parent().get_node("BackSound").play()
	
	hide()
