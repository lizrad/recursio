extends Control
class_name GameRoomMenu

signal btn_back_pressed()


onready var _game_room_search: GameRoomSearch = get_node("CenterContainer/GameRoomSearch")


func _ready():
	_game_room_search.connect("btn_back_pressed", self, "_on_back_pressed")


func show_game_room_search():
	_game_room_search.show()


func hide_game_room_search():
	_game_room_search.hide()


func _on_back_pressed():
	emit_signal("btn_back_pressed")
	self.hide()
