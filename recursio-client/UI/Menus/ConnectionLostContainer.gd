 extends PanelContainer


onready var _back_button = get_node("SettingsList/BackButton")

func _ready():
	_back_button.connect("pressed", self, "_on_back_button_pressed")

func _on_back_button_pressed():
	hide()
