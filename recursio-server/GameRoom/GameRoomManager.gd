extends Node
# Creates and removes game_rooms, and mediates between Server requests and specific game_rooms.
class_name GameRoomManager

onready var _server = get_parent()
onready var _debug_room = Constants.get_value("debug", "debug_room_enabled")

var game_room_count: int = 0

var _game_room_scene = preload("res://GameRoom/GameRoom.tscn")

var _game_room_id_counter: int = 1
# GameRoom id <-> GameRoom
var _game_room_dic: Dictionary = {}
# Player id <-> GameRoom id
var _player_game_room_dic: Dictionary = {}


func _ready():
	_server.connect("peer_disconnected", self, "_on_peer_disconnected")
	
	_server.connect("player_input_data_received", self, "_on_player_input_data_received") 
	_server.connect("player_ready", self, "_on_player_ready_received") 
	_server.connect("player_timeline_pick_received", self, "_on_player_timline_pick_received")
	
	_server.connect("create_game_room_received", self, "_on_create_game_room_received")
	_server.connect("get_game_rooms_received", self, "_on_get_game_rooms_received")
	_server.connect("join_game_room_received", self, "_on_join_game_room_received")
	_server.connect("leave_game_room_received", self, "_on_leave_game_room_received")
	
	_server.connect("game_room_ready_received", self, "_on_game_room_ready_received")
	_server.connect("game_room_not_ready_received", self, "_on_game_room_not_ready_received")
	_server.connect("level_loaded_received", self, "_on_level_loaded_received")
	
	_server.connect("leave_game_received", self, "_on_leave_game_received")
	
	_server.connect("get_game_room_owner_received", self, "_on_get_game_room_owner")
	_server.connect("level_selected_received", self, "_on_level_selected")
	_server.connect("fog_of_war_toggled_received", self, "_on_fog_of_war_toggled")
	
	if _debug_room:
		var _game_room_id = _create_game_room("GameRoom")


func _create_game_room(game_room_name: String) -> int:
	var game_room: GameRoom = _game_room_scene.instance()
	game_room.set_name(str(_game_room_id_counter))
	game_room.game_room_name = game_room_name
	game_room.id = _game_room_id_counter
	$ViewportContainer.add_child(game_room)
	
	# Workaround for getting the viewport to update
	$ViewportContainer.rect_clip_content = true

	var _error = game_room.connect("world_state_updated", self, "_on_world_state_update") 
	
	_game_room_dic[_game_room_id_counter] = game_room
	_game_room_id_counter += 1
	game_room_count += 1
	Logger.info("GameRoom added (ID:%s)" % game_room.id, "game_rooms")
	return game_room.id


func _delete_game_room(game_room_id: int) -> void:
	if _game_room_dic.has(game_room_id):
		_game_room_dic[game_room_id].free()
		var _success = _game_room_dic.erase(game_room_id)
		game_room_count -= 1
		Logger.info("GameRoom removed (ID:%s)" % game_room_id, "game_rooms")
		
		# Same workaround as in create_game_room
		$ViewportContainer.rect_clip_content = true


func _join_game_room(player_id: int, game_room_id: int, player_user_name: String) -> void:
	if _game_room_dic.has(game_room_id):
		var game_room: GameRoom = _game_room_dic[game_room_id]
		if game_room.get_player_count() == Constants.PLAYER_MAX_COUNT:
			return;
		
		game_room.add_player(player_id, player_user_name)
		
		if player_id != game_room.get_owning_player_id():
			_server.send_level_selected(player_id, game_room.get_selected_level_index())
			_server.send_fog_of_war_toggled(player_id, game_room.get_fog_of_war_enabled())
		
		_player_game_room_dic[player_id] = game_room_id
		_update_game_room_on_client(game_room)


func _leave_game_room(player_id: int, game_room_id: int) -> void:
	if _game_room_dic.has(game_room_id):
		var game_room: GameRoom = _game_room_dic[game_room_id]
		game_room.remove_player(player_id)
		
		if game_room.get_player_count() == 0:
			_delete_game_room(game_room_id)
		else:
			if game_room.get_game_room_world_exists():
				game_room.despawn_world()
			
			var remaining_player_id = game_room.get_game_room_players().keys().front()
			game_room.set_owning_player(remaining_player_id)
			_server.send_game_room_owner(remaining_player_id, remaining_player_id)
			_update_game_room_on_client(game_room)


func _get_game_room(game_room_id: int) -> GameRoom:
	return _game_room_dic[game_room_id]


func _get_current_game_room_id() -> int:
	return _game_room_dic[_game_room_id_counter - 1].id


func _is_current_game_room_full() -> bool:
	if _game_room_dic.size() == 0:
		return true
	else:
		return _game_room_dic[_game_room_id_counter - 1].player_count >= 2


func _on_peer_disconnected(player_id):
	if _player_game_room_dic.has(player_id):
		if _game_room_dic.has(_player_game_room_dic[player_id]):
			var game_room: GameRoom = _get_game_room(_player_game_room_dic[player_id])
			# If there is a player remaining in game, notify him
			if game_room.get_game_room_world_exists():
				for client_id in game_room.get_game_room_players():
					_server.send_player_disconnected(client_id, player_id)
		_leave_game_room(player_id, _player_game_room_dic[player_id])
		var _succes = _player_game_room_dic.erase(player_id)


func _on_player_input_data_received(player_id, input_data):
	var game_room_id = _player_game_room_dic[player_id]
	var data = InputData.new().from_array(input_data)
	_get_game_room(game_room_id).update_player_input_data(player_id, data)


func _on_player_ready_received(player_id):
	Logger.info("received player ready for player " + str(player_id), "connection")
	var game_room_id = _player_game_room_dic[player_id]
	_get_game_room(game_room_id).handle_player_ready(player_id)


func _on_player_timline_pick_received(player_id, timeline_index):
	Logger.info("received timeline index of " + str(timeline_index)+" from player " + str(player_id), "connection")
	var game_room_id = _player_game_room_dic[player_id]
	_get_game_room(game_room_id).handle_ghost_pick(player_id, timeline_index)


# Sends the world state of the game_room to all players in the game_room
func _on_world_state_update(world_state, game_room_id) -> void:
	var game_room: GameRoom = _game_room_dic[game_room_id]
	for player_id in game_room.get_game_room_players():
		_server.send_world_state(player_id, world_state)


##############################
#### Game Room Management ####
##############################

func _on_create_game_room_received(player_id, game_room_name) -> void:
	var game_room_id = _create_game_room(game_room_name)
	_server.send_game_room_created(player_id, game_room_id, game_room_name)


func _on_get_game_rooms_received(player_id) -> void:
	var game_rooms := {}
	for game_room_id in _game_room_dic:
		game_rooms[game_room_id] = _game_room_dic[game_room_id].game_room_name
	_server.send_game_rooms(player_id, game_rooms)


func _on_join_game_room_received(player_id, game_room_id, player_user_name) -> void:
	_join_game_room(player_id, game_room_id, player_user_name)


func _on_leave_game_room_received(player_id, game_room_id) -> void:
	_leave_game_room(player_id, game_room_id)


func _on_game_room_ready_received(player_id, game_room_id):
	if _game_room_dic.has(game_room_id):
		_get_game_room(game_room_id).handle_game_room_ready(player_id)


func _on_game_room_not_ready_received(player_id, game_room_id):
	_get_game_room(game_room_id).handle_game_room_not_ready(player_id)


func _on_level_loaded_received(player_id):
	_get_game_room(_player_game_room_dic[player_id]).handle_player_level_loaded(player_id)


func _update_game_room_on_client(game_room):
	var player_dic = game_room.get_game_room_players()
	var players_ready_dic = game_room.get_game_room_players_ready()
	var player_id_name_dic := {}
	for player_id in player_dic:
		player_id_name_dic[player_id] = player_dic[player_id]
	
	for player_id in player_dic:
		_server.send_game_room_joined(player_id, player_id_name_dic, game_room.id)

		for other_player_id in players_ready_dic:
			_server.send_game_room_ready(player_id, other_player_id)


func _on_leave_game_received(player_left_id):
	var game_room: GameRoom = _get_game_room(_player_game_room_dic[player_left_id])
	var player_dic = game_room.get_game_room_players()
	if game_room.get_game_room_world_exists():
		game_room.despawn_world()
		_update_game_room_on_client(game_room)
		for player_id in player_dic:
			_server.send_player_left_game(player_id, player_left_id)


func _on_get_game_room_owner(client_id) -> void:
	var game_room: GameRoom = _game_room_dic[_player_game_room_dic[client_id]]
	_server.send_game_room_owner(client_id, game_room.get_owning_player_id())


func _on_level_selected(player_id, level_index) -> void:
	var game_room: GameRoom = _game_room_dic[_player_game_room_dic[player_id]]
	game_room.set_selected_level(level_index)
	for client_id in game_room.get_game_room_players():
		_server.send_level_selected(client_id, level_index)


func _on_fog_of_war_toggled(player_id, is_fog_of_war_enabled) -> void:
	var game_room: GameRoom = _game_room_dic[_player_game_room_dic[player_id]]
	game_room.set_fog_of_war_enabled(is_fog_of_war_enabled)
	for client_id in game_room.get_game_room_players():
		_server.send_fog_of_war_toggled(client_id, is_fog_of_war_enabled)



