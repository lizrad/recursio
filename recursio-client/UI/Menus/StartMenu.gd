extends Control
class_name StartMenu

onready var _start_menu_buttons: VBoxContainer = get_node("CenterContainer/MainMenu")

onready var btn_play_tutorial = get_node("CenterContainer/MainMenu/Btn_PlayTutorial")
onready var btn_play_online = get_node("CenterContainer/MainMenu/Btn_PlayOnline")
onready var btn_exit = get_node("CenterContainer/MainMenu/Btn_Exit")

onready var _game_room_search: GameRoomSearch = get_node("CenterContainer/GameRoomSearch")
onready var _game_room_creation: GameRoomCreation = get_node("CenterContainer/GameRoomCreation")



func _ready():
	btn_play_tutorial.connect("pressed", self, "_on_play_tutorial")
	btn_play_online.connect("pressed", self, "_on_play_online")
	btn_exit.connect("pressed", self, "_on_exit")
	
	
	_game_room_search.connect("btn_create_game_room_pressed", self, "_on_search_create_game_room_pressed")
	_game_room_search.connect("btn_back_pressed", self, "_on_search_back_pressed")
	_game_room_search.connect("btn_join_game_room_pressed", self, "_on_join_game_room_pressed")
	
	_game_room_creation.connect("btn_create_game_room_pressed", self, "_on_creation_create_game_room_pressed")
	_game_room_creation.connect("btn_back_pressed", self, "_on_creation_back_pressed")


func _on_play_tutorial():
	pass


func _on_play_online():
	_start_menu_buttons.hide()
	_game_room_search.show()


func _on_exit():
	get_tree().quit()


func _on_search_create_game_room_pressed():
	_game_room_creation.show()


func _on_creation_create_game_room_pressed(game_room_name):
	Server.send_create_game_room(game_room_name)


func _on_search_back_pressed():
	_start_menu_buttons.show()


func _on_creation_back_pressed():
	_game_room_search.show()


func _on_join_game_room_pressed():
	self.hide()
