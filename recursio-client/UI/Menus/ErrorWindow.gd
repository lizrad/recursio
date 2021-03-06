 extends PanelContainer
class_name ErrorWindow

onready var _back_button = get_node("VBoxContainer/BackButton")
onready var _title: Label = get_node("VBoxContainer/Header")
onready var _content: Label = get_node("VBoxContainer/LabelSpacePlaceholder/Label")

func _ready() -> void:
	var _error = _back_button.connect("pressed", self, "_on_back_button_pressed")
	_error = self.connect("visibility_changed", self, "_on_visibility_changed")


func set_title(title: String) -> void:
	_title.text = title


func set_content(content: String) -> void:
	_content.text = content


func _on_back_button_pressed() -> void:
	hide()


func _on_visibility_changed() -> void:
	if self.visible:
		_back_button.grab_focus()
