extends Control
class_name GameplayMenu

signal leave_pressed()

onready var _btn_resume: Button = get_node("CenterContainer/VBoxContainer/Btn_Resume")
onready var _btn_settings: Button = get_node("CenterContainer/VBoxContainer/Btn_Settings")
onready var _btn_leave: Button = get_node("CenterContainer/VBoxContainer/Btn_Leave")

onready var _settings: Control = get_node("CenterContainer/SettingsContainer")


func _ready():
	var _err = _btn_resume.connect("pressed", self, "_on_resume_pressed")
	_err = _btn_settings.connect("pressed", self, "_on_settings_pressed")
	_err = _btn_leave.connect("pressed", self, "_on_leave_pressed")


func _on_resume_pressed() -> void:
	self.hide()


func _on_settings_pressed() -> void:
	_settings.show()


func _on_leave_pressed() -> void:
	self.hide()
	emit_signal("leave_pressed")
