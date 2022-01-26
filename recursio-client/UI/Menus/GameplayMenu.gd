extends Control
class_name GameplayMenu

signal leave_pressed()
signal resume_pressed()

onready var _btn_resume: Button = get_node("CenterContainer/VBoxContainer/Btn_Resume")
onready var _btn_settings: Button = get_node("CenterContainer/VBoxContainer/Btn_Settings")
onready var _btn_leave: Button = get_node("CenterContainer/VBoxContainer/Btn_Leave")
onready var _btn_exit: Button = get_node("CenterContainer/VBoxContainer/Btn_Exit")

onready var _settings: Control = get_node("CenterContainer/SettingsContainer")


func _ready():
	var _err = _btn_resume.connect("pressed", self, "_on_resume_pressed")
	_err = _btn_settings.connect("pressed", self, "_on_settings_pressed")
	_err = _btn_leave.connect("pressed", self, "_on_leave_pressed")
	_err = _btn_exit.connect("pressed", self, "_on_exit_pressed")
	_err = self.connect("visibility_changed", self, "_on_visibility_changed")
	_err = _settings.connect("visibility_changed", self, "_on_settings_visibility_changed")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if _settings.visible:
			_settings.hide()


func _on_visibility_changed() -> void:
	if visible:
		_btn_resume.grab_focus()
	else:
		_settings.hide()


func _on_settings_visibility_changed() -> void:
	if not _settings.visible:
		_btn_settings.grab_focus()


func _on_resume_pressed() -> void:
	self.hide()
	emit_signal("resume_pressed")


func _on_settings_pressed() -> void:
	_settings.show()


func _on_leave_pressed() -> void:
	self.hide()
	emit_signal("leave_pressed")


func _on_exit_pressed() -> void:
	get_tree().quit()
