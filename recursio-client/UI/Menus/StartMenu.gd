extends Control
class_name StartMenu

onready var _start_menu_buttons: VBoxContainer = get_node("CenterContainer/MainMenu")

onready var btn_play_tutorial = get_node("CenterContainer/MainMenu/Btn_PlayTutorial")
onready var btn_play_online = get_node("CenterContainer/MainMenu/Btn_PlayOnline")
onready var btn_exit = get_node("CenterContainer/MainMenu/Btn_Exit")

onready var _game_room_search: GameRoomSearch = get_node("CenterContainer/GameRoomSearch")
onready var _game_room_creation: GameRoomCreation = get_node("CenterContainer/GameRoomCreation")
onready var _game_room_ui: GameRoomUI = get_node("CenterContainer/GameRoom")

onready var _character_manager: CharacterManager = get_node("../CharacterManager")
onready var _debug_room = Constants.get_value("debug", "debug_room_enabled")

var _in_game_room: bool = false

func _ready():
	btn_play_tutorial.connect("pressed", self, "_on_play_tutorial")
	btn_play_online.connect("pressed", self, "_on_play_online")
	btn_exit.connect("pressed", self, "_on_exit")
	
	
	_game_room_search.connect("btn_create_game_room_pressed", self, "_on_search_create_game_room_pressed")
	_game_room_search.connect("btn_back_pressed", self, "_on_search_back_pressed")
	_game_room_search.connect("btn_join_game_room_pressed", self, "_on_join_game_room_pressed")
	
	_game_room_creation.connect("btn_create_game_room_pressed", self, "_on_creation_create_game_room_pressed")
	_game_room_creation.connect("btn_back_pressed", self, "_on_creation_back_pressed")
	
	_game_room_ui.connect("btn_ready_pressed", self, "_on_game_room_ready_pressed")
	_game_room_ui.connect("btn_leave_pressed", self, "_on_game_room_leave_pressed")
	
	Server.connect("game_room_created", self, "_on_game_room_created")
	Server.connect("game_rooms_received", self, "_on_game_rooms_received")
	Server.connect("game_room_joined", self, "_on_game_room_joined")
	Server.connect("successfully_connected" , self, "_on_successfully_connected") 
	
	_character_manager.connect("game_started", self, "_on_game_started")


func _on_successfully_connected():
	if _debug_room:
		_game_room_search.add_game_room(1, "GameRoom")
		Server.send_join_game_room(1, "Player")
		Server.send_game_room_ready(1)


func _on_play_tutorial() -> void:
	pass


func _on_play_online() -> void:
	_start_menu_buttons.hide()
	_game_room_search.show()


func _on_exit() -> void:
	get_tree().quit()


func _on_search_create_game_room_pressed() -> void:
	_game_room_creation.show()


func _on_creation_create_game_room_pressed(game_room_name) -> void:
	Server.send_create_game_room(game_room_name)


func _on_search_back_pressed() -> void:
	_start_menu_buttons.show()


func _on_creation_back_pressed() -> void:
	_game_room_search.show()


func _on_join_game_room_pressed() -> void:
	var selected_room = _game_room_search.get_selected_game_room()
	if selected_room != -1:
		Server.send_join_game_room(selected_room, _character_manager.get_player_user_name())


func _on_game_room_ready_pressed() -> void:
	pass


func _on_game_room_leave_pressed() -> void:
	_in_game_room = false
	_game_room_search.show()


func _on_game_room_created(game_room_id, game_room_name) -> void:
	_game_room_search.add_game_room(game_room_id, game_room_name)
	_game_room_creation.hide()


func _on_game_rooms_received(game_room_dic) -> void:
	_game_room_search.set_game_rooms(game_room_dic)


func _on_game_room_joined(player_id_name_dic, game_room_id):
	_game_room_ui.set_players(player_id_name_dic)
	
	if _in_game_room:
		return
	_in_game_room = true
	
	_game_room_creation.hide()
	_game_room_search.hide()
	_game_room_ui.show()
	_game_room_ui.init(game_room_id, _game_room_search.get_game_room_name(game_room_id))


func _on_game_started():
	self.hide()
