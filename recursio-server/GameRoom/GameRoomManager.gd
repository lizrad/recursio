extends Node
# Creates and removes game_rooms, and mediates between Server requests and specific game_rooms.
class_name GameRoomManager

onready var _server = get_parent()

var game_room_count: int = 0

var _game_room_scene = preload("res://GameRoom/GameRoom.tscn")

var _game_room_id_counter: int = 1
# GameRoom id <-> GameRoom
var _game_room_dic: Dictionary = {}
# Player id <-> GameRoom id
var _player_game_room_dic: Dictionary = {}


func _ready():
	_server.connect("peer_connected", self, "_on_peer_connected") 
	_server.connect("peer_disconnected", self, "_on_peer_disconnected") 
	_server.connect("player_input_data_received", self, "_on_player_input_data_received") 
	_server.connect("player_ready", self, "_on_player_ready_received") 
	_server.connect("player_timeline_pick_received", self, "_on_player_timline_pick_received")
	
	_server.connect("create_game_room_received", self, "_on_create_game_room_received")
	_server.connect("get_game_rooms_received", self, "_on_get_game_rooms_received")
	_server.connect("join_game_room_received", self, "_on_join_game_room_received")
	_server.connect("leave_game_room_received", self, "_on_leave_game_room_received")
	
	_server.connect("game_room_ready_received", self, "_on_game_room_ready_received")


func _create_game_room(game_room_name: String) -> int:
	var game_room: GameRoom = _game_room_scene.instance()
	game_room.set_name(str(_game_room_id_counter))
	game_room.game_room_name = game_room_name
	game_room.id = _game_room_id_counter
	$ViewportContainer.add_child(game_room)
	
	# Workaround for getting the viewport to update
	$ViewportContainer.rect_clip_content = true

	var _error = game_room.connect("world_state_updated", self, "_on_world_state_update") 
	
	_error = game_room.get_game_manager().connect("capture_point_team_changed", self, "_on_capture_point_team_changed", [game_room.id]) 
	_error = game_room.get_game_manager().connect("capture_point_captured", self, "_on_capture_point_captured", [game_room.id]) 
	_error = game_room.get_game_manager().connect("capture_point_status_changed", self, "_on_capture_point_status_changed", [game_room.id]) 
	_error = game_room.get_game_manager().connect("capture_point_capture_lost", self, "_on_capture_point_capture_lost", [game_room.id]) 
	_error = game_room.get_game_manager().connect("game_result", self, "_on_game_result", [game_room.id]) 
	
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
		game_room.add_player(player_id, player_user_name)
		_player_game_room_dic[player_id] = game_room_id
		_update_game_room_on_client(game_room)


func _leave_game_room(player_id: int, game_room_id: int) -> void:
	if _game_room_dic.has(game_room_id):
		var game_room: GameRoom = _game_room_dic[game_room_id]
		game_room.remove_player(player_id)
		_update_game_room_on_client(game_room)
		if game_room.player_count == 0:
			_delete_game_room(game_room_id)


func _get_game_room(game_room_id: int) -> GameRoom:
	return _game_room_dic[game_room_id]


func _get_current_game_room_id() -> int:
	return _game_room_dic[_game_room_id_counter - 1].id


func _is_current_game_room_full() -> bool:
	if _game_room_dic.size() == 0:
		return true
	else:
		return _game_room_dic[_game_room_id_counter - 1].player_count >= 2



func _on_peer_connected(player_id):
	pass


func _on_peer_disconnected(player_id):
	if _player_game_room_dic.has(player_id):
		_leave_game_room(_player_game_room_dic[player_id], player_id)
		var _succes = _player_game_room_dic.erase(player_id)


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
	for player_id in game_room.get_players():
		_server.send_world_state(player_id, world_state)


func _on_capture_point_team_changed(team_id, capture_point, game_room_id):
	var game_room = _game_room_dic[game_room_id]
	var capturing_player_id = -1
	if team_id != -1:
		capturing_player_id = game_room.team_id_to_player_id[team_id]
	for player_id in game_room.get_players():
		_server.send_capture_point_team_changed(player_id, capturing_player_id, capture_point)


func _on_capture_point_captured(team_id, capture_point, game_room_id):
	var game_room = _game_room_dic[game_room_id]
	var capturing_player_id = -1
	if team_id != -1:
		capturing_player_id = game_room.team_id_to_player_id[team_id]
	for player_id in game_room.get_players():
		_server.send_capture_point_captured(player_id, capturing_player_id, capture_point)

func _on_capture_point_status_changed(capture_progress, team_id, capture_point, game_room_id):
	var game_room = _game_room_dic[game_room_id]
	var capturing_player_id = -1
	if team_id != -1:
		capturing_player_id = game_room.team_id_to_player_id[team_id]
	for player_id in game_room.get_players():
		_server.send_capture_point_status_changed(player_id, capturing_player_id, capture_point, capture_progress)

func _on_capture_point_capture_lost(team_id, capture_point, game_room_id):
	var game_room = _game_room_dic[game_room_id]
	var capturing_player_id = -1
	if team_id != -1:
		capturing_player_id = game_room.team_id_to_player_id[team_id]
	for player_id in game_room.get_players():
		_server.send_capture_point_capture_lost(player_id, capturing_player_id, capture_point)

func _on_game_result(team_id, game_room_id):
	var game_room = _game_room_dic[game_room_id]
	var winning_player_id = game_room.team_id_to_player_id[team_id]
	for player_id in game_room.get_players():
		_server.send_game_result(player_id, winning_player_id)
	game_room.reset()
	game_room.start_game()


func _on_game_room_ready_received(player_id, game_room_id):
	_get_game_room(game_room_id).handle_game_room_ready(player_id)


func _update_game_room_on_client(game_room):
	var player_dic = game_room.get_game_room_players()
	var player_id_name_dic := {}
	for player_id in player_dic:
		player_id_name_dic[player_id] = player_dic[player_id]
	
	for player_id in player_dic:
		_server.send_game_room_joined(player_id, player_id_name_dic, game_room.id)
