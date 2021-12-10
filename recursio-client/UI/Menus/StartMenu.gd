extends Control
class_name StartMenu

const REMOTE_SERVER_IP: String = "37.252.189.118"

export var world_scene: PackedScene
export var level_scene: PackedScene
export var capture_point_scene: PackedScene
export var spawn_point_scene: PackedScene

onready var _start_menu_buttons: VBoxContainer = get_node("CenterContainer/MainMenu")

onready var _btn_play_tutorial = get_node("CenterContainer/MainMenu/PlayTutorial")
onready var _btn_play_online = get_node("CenterContainer/MainMenu/PlayOnline")
onready var _btn_play_local = get_node("CenterContainer/MainMenu/HBoxContainer/Btn_PlayLocal")
onready var _lineEdit_local_ip = get_node("CenterContainer/MainMenu/HBoxContainer/LocalIPAddress")
onready var _btn_settings = get_node("CenterContainer/MainMenu/SettingsButton")
onready var _btn_exit = get_node("CenterContainer/MainMenu/Btn_Exit")

onready var _game_room_search: GameRoomSearch = get_node("CenterContainer/GameRoomSearch")
onready var _game_room_creation: GameRoomCreation = get_node("CenterContainer/GameRoomCreation")
onready var _game_room_lobby: GameRoomLobby = get_node("CenterContainer/GameRoomLobby")

onready var _debug_room = Constants.get_value("debug", "debug_room_enabled")

onready var _random_names = TextFileToArray.load_text_file("res://Resources/Data/animal_names.txt")

var _player_user_name: String
var _player_rpc_id: int

var _in_game_room: bool = false

var _world

func _ready():
	var _error = _btn_play_tutorial.connect("pressed", self, "_on_play_tutorial")
	_error = _btn_play_online.connect("pressed", self, "_on_play_online")
	_error = _btn_play_local.connect("pressed", self, "_on_play_local")
	_error = _btn_settings.connect("pressed", self, "_on_open_settings")
	_error = _btn_exit.connect("pressed", self, "_on_exit")

	_error = _game_room_search.connect("btn_create_game_room_pressed", self, "_on_search_create_game_room_pressed")
	_error = _game_room_search.connect("btn_back_pressed", self, "_on_search_back_pressed")
	_error = _game_room_search.connect("btn_join_game_room_pressed", self, "_on_join_game_room_pressed")
	_error = _game_room_search.connect("visibility_changed", self, "_on_room_search_visibility_changed")

	_error = _game_room_creation.connect("btn_create_game_room_pressed", self, "_on_creation_create_game_room_pressed")
	_error = _game_room_creation.connect("btn_back_pressed", self, "_on_creation_back_pressed")

	_error = _game_room_lobby.connect("btn_leave_pressed", self, "_on_game_room_leave_pressed")
	
	_error = Server.connect("server_disconnected", self, "_on_server_disconnected")
	_error = Server.connect("connection_failed", self, "_on_connection_failed")
	
	_error = Server.connect("game_room_created", self, "_on_game_room_created")
	_error = Server.connect("game_rooms_received", self, "_on_game_rooms_received")
	_error = Server.connect("game_room_joined", self, "_on_game_room_joined")
	_error = Server.connect("connection_successful" , self, "_on_connection_successful")
	_error = Server.connect("game_room_ready_received" , self, "_on_game_room_ready_received")
	_error = Server.connect("game_room_not_ready_received" , self, "_on_game_room_not_ready_received")
	_error = Server.connect("load_level_received", self, "_on_load_level_received")
	_error = Server.connect("game_result", self, "_on_game_result_received")

	_btn_play_tutorial.grab_focus()

	randomize()
	var random_index = randi() % _random_names.size()
	_player_user_name = _random_names[random_index]


func _return_to_game_room_lobby():
	_world.queue_free()
	_world = null
	_game_room_lobby.reset_players()
	$CenterContainer.show()


func _toggle_enabled_start_menu_buttons(enabled: bool):
	_btn_play_online.disabled = !enabled
	_btn_play_local.disabled = !enabled
	_btn_play_tutorial.disabled = !enabled
	_btn_exit.disabled = !enabled


func _on_connection_successful():
	_player_rpc_id = get_tree().get_network_unique_id()
	_start_menu_buttons.hide()
	_game_room_search.show()
	if _debug_room:
		_game_room_search.add_game_room(1, "GameRoom")
		Server.send_join_game_room(1, "Player")
		Server.send_game_room_ready(1)
	else:
		# Load all rooms by default when opening search window
		Server.send_get_game_rooms()


func _on_server_disconnected():
	if _world != null:
		_world.queue_free()
		_world = null
	# Reset all sub screens
	_game_room_creation.hide()
	_game_room_lobby.hide()
	_game_room_lobby.reset()
	_game_room_search.hide()
	_game_room_search.reset()
	_in_game_room = false
	# Show start screen
	_start_menu_buttons.show()
	$CenterContainer.show()
	_toggle_enabled_start_menu_buttons(true)
	_btn_play_tutorial.grab_focus()


func _on_connection_failed():
	_toggle_enabled_start_menu_buttons(true)


func _on_play_tutorial() -> void:
	$ClickSound.play()
	yield($ClickSound, "finished")
	
	get_tree().change_scene("res://Tutorial/Tutorial.tscn")


func _on_play_online() -> void:
	$ClickSound.play()
	
	_toggle_enabled_start_menu_buttons(false)
	Server.connect_to_server(REMOTE_SERVER_IP)


func _on_play_local() -> void:
	$ClickSound.play()
	
	_toggle_enabled_start_menu_buttons(false)
	Server.connect_to_server(_lineEdit_local_ip.text)


func _on_open_settings() -> void:
	$ClickSound.play()
	
	$CenterContainer/SettingsContainer.show()


func _on_exit() -> void:
	$BackSound.play()
	
	get_tree().quit()


func _on_search_create_game_room_pressed() -> void:
	$ClickSound.play()
	
	# just create room with default naming
	# 	otherwise would need virtual keyboard vor controller support
	#_game_room_creation.show()
	_on_creation_create_game_room_pressed("GameRoom")


func _on_creation_create_game_room_pressed(game_room_name) -> void:
	$ClickSound.play()
	
	Server.send_create_game_room(game_room_name)


func _on_search_back_pressed() -> void:
	$BackSound.play()
	
	_start_menu_buttons.show()
	Server.disconnect_from_server()
	


func _on_creation_back_pressed() -> void:
	$BackSound.play()
	
	_game_room_search.show()


func _on_join_game_room_pressed() -> void:
	$ClickSound.play()
	
	var selected_room = _game_room_search.get_selected_game_room()
	if selected_room != -1:
		Server.send_join_game_room(selected_room, _player_user_name)

func _on_room_search_visibility_changed() -> void:
	_btn_play_tutorial.grab_focus()


func _on_game_room_leave_pressed() -> void:
	$BackSound.play()
	
	_in_game_room = false
	_game_room_search.show()


func _on_game_room_created(game_room_id, game_room_name) -> void:
	$ClickSound.play()
	
	_game_room_search.add_game_room(game_room_id, game_room_name)
	_game_room_creation.hide()

	Server.send_join_game_room(game_room_id, _player_user_name)


func _on_game_rooms_received(game_room_dic) -> void:
	_game_room_search.set_game_rooms(game_room_dic)


func _on_game_room_joined(player_id_name_dic, game_room_id):
	_game_room_lobby.set_players(player_id_name_dic, _player_rpc_id)
	
	if _world != null:
		_return_to_game_room_lobby()
		return
	
	if _in_game_room:
		return

	_in_game_room = true
	
	_game_room_creation.hide()
	_game_room_search.hide()
	_game_room_lobby.show()
	_game_room_lobby.init(game_room_id, _game_room_search.get_game_room_name(game_room_id))


func _on_game_room_ready_received(player_id):
	$ClickSound.play()
	
	if player_id == _player_rpc_id:
		_game_room_lobby.toggle_ready_button(true)
	_game_room_lobby.set_player_ready(player_id, true)


func _on_game_room_not_ready_received(player_id):
	$BackSound.play()
	
	if player_id == _player_rpc_id:
		_game_room_lobby.toggle_ready_button(false)
	_game_room_lobby.set_player_ready(player_id, false)


func _on_load_level_received():
	$CenterContainer.hide()
	_world = world_scene.instance()
	var level = level_scene.instance()
	level.capture_point_scene = capture_point_scene
	add_child(_world)
	level.spawn_point_scene = spawn_point_scene
	_world.set_level(level)
	_world.add_child(level)
	_world.level_set_up_done()


func _on_game_result_received(_winning_player_id):
	yield(get_tree().create_timer(3), "timeout")
	_return_to_game_room_lobby()

