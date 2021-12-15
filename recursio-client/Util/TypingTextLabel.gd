extends RichTextLabel
class_name TypingTextLabel

signal typing_completed()

export(float) var typing_speed = 20.0

var _number_of_characters: int = 0
var _number_of_visible_characters: float = 0


var typing_text setget set_typing_text, get_typing_text


func _ready():
	self.visible_characters = 0


func _process(delta):
	if _number_of_visible_characters >= _number_of_characters:
		set_process(false)
		self.visible_characters = -1
		emit_signal("typing_completed")
		return
	
	var step_size = typing_speed * delta
	
	_number_of_visible_characters += step_size
	self.visible_characters = _number_of_visible_characters


func set_typing_text(typing_text) -> void:
	_number_of_visible_characters = 0
	self.visible_characters = 0
	_number_of_characters = typing_text.length()
	.set_text(typing_text)
	set_process(true)


func get_typing_text() -> String:
	return self.text


func get_typing_time() -> float:
	return _number_of_characters / typing_speed


func set_text_field_size(size: Vector2) -> void:
	self.rect_min_size = size
