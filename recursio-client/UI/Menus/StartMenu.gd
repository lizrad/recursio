extends Control
class_name StartMenu

onready var _game_room_menu: GameRoomMenu = get_node("GameRoomMenu")
onready var _start_menu_content: CenterContainer = get_node("CenterContainer")

onready var btn_play_tutorial = get_node("CenterContainer/Buttons/Btn_PlayTutorial")
onready var btn_play_online = get_node("CenterContainer/Buttons/Btn_PlayOnline")
onready var btn_exit = get_node("CenterContainer/Buttons/Btn_Exit")


func _ready():
	btn_play_tutorial.connect("pressed", self, "_on_play_tutorial")
	btn_play_online.connect("pressed", self, "_on_play_online")
	btn_exit.connect("pressed", self, "_on_exit")
	
	_game_room_menu.connect("btn_back_pressed", self, "_on_game_room_menu_back")


func _on_play_tutorial():
	pass


func _on_play_online():
	_start_menu_content.hide()
	_game_room_menu.show()


func _on_exit():
	get_tree().quit()


func _on_game_room_menu_back():
	_start_menu_content.show()
