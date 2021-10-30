extends Node
class_name RoomManager

# Creates and removes rooms, and mediates between Server requests and specific rooms.

var room_count: int = 0

var _room_scene = preload("res://Room/Room.tscn")

var _room_id_counter: int = 1
# Room id <-> Room
var _room_dic: Dictionary = {}
# Player id <-> Room id
var _player_room_dic: Dictionary = {}

var _player_amount: int = 0

func _ready():
	assert(Server.connect("peer_connected", self, "_on_peer_connected") == OK)
	assert(Server.connect("peer_disconnected", self, "_on_peer_connected") == OK)
	assert(Server.connect("player_input_data_received", self, "_on_player_input_data_received") == OK)


func _create_room(room_name: String) -> int:
	var room: Room = _room_scene.instance()
	room.set_name(str(_room_id_counter))
	room.room_name = room_name
	room.id = _room_id_counter
	$ViewportContainer.add_child(room)
	
	# Workaround for getting the viewport to update
	$ViewportContainer.rect_clip_content = true

	assert(room.connect("world_state_updated", self, "_on_world_state_update") == OK)
	assert(room.get_game_manager().connect("round_started", self, "_on_round_start", [room.id]) == OK)
	assert(room.get_game_manager().connect("round_ended", self, "_on_round_end", [room.id]) == OK)
	assert(room.get_game_manager().connect("capture_point_team_changed", self, "_on_capture_point_team_changed", [room.id]) == OK)
	assert(room.get_game_manager().connect("capture_point_captured", self, "_on_capture_point_captured", [room.id]) == OK)
	assert(room.get_game_manager().connect("capture_point_status_changed", self, "_on_capture_point_status_changed", [room.id]) == OK)
	assert(room.get_game_manager().connect("capture_point_capture_lost", self, "_on_capture_point_capture_lost", [room.id]) == OK)
	assert(room.get_game_manager().connect("game_result", self, "_on_game_result", [room.id]) == OK)
	
	_room_dic[_room_id_counter] = room
	_room_id_counter += 1
	room_count += 1
	Logger.info("Room added (ID:%s)" % room.id, "rooms")
	return room.id


func _delete_room(room_id: int) -> void:
	if _room_dic.has(room_id):
		_room_dic[room_id].free()
		_room_dic.erase(room_id)
		room_count -= 1
		Logger.info("Room removed (ID:%s)" % room_id, "rooms")
		
		# Same workaround as in create_room
		$ViewportContainer.rect_clip_content = true


func _join_room(room_id: int, player_id: int) -> void:
	if _room_dic.has(room_id):
		var room: Room = _room_dic[room_id]
		room.add_player(player_id)


func _leave_room(room_id: int, player_id: int) -> void:
	if _room_dic.has(room_id):
		var room: Room = _room_dic[room_id]
		room.remove_player(player_id)
		if room.player_count == 0:
			_delete_room(room_id)


func _get_room(room_id: int) -> Room:
	return _room_dic[room_id]


func _get_current_room_id() -> int:
	return _room_dic[_room_id_counter - 1].id


func _is_current_room_full() -> bool:
	if _room_dic.size() == 0:
		return true
	else:
		return _room_dic[_room_id_counter - 1].player_count >= 2



func _on_peer_connected(player_id):
	_player_amount += 1

	if _is_current_room_full():
		var room_id = _create_room("Room 1")
		_join_room(room_id, player_id)
		_player_room_dic[player_id] = room_id
	else:
		var room_id = _get_current_room_id()
		_join_room(room_id, player_id)
		_player_room_dic[player_id] = room_id


func _on_peer_disconnect(player_id):
	_leave_room(_player_room_dic[player_id], player_id)
	_player_room_dic.erase(player_id)
	_player_amount -= 1


func _on_player_input_data_received(player_id, input_data):
	var room_id = _player_room_dic[player_id]
	var data = InputData.new().from_array(input_data)
	_get_room(room_id).update_player_input_data(player_id, data)


func _on_player_timline_pick_received(player_id, timeline_index):
	Logger.info("received timeline index of " + str(timeline_index)+" from player " + str(player_id), "connection")
	var room_id = _player_room_dic[player_id]
	_get_room(room_id).handle_ghost_pick(player_id, timeline_index)


# Sends the world state of the room to all players in the room
func _on_world_state_update(world_state, room_id) -> void:
	var room: Room = _room_dic[room_id]
	for player_id in room.get_players():
		Server.send_world_state(player_id, world_state)


# Sends the round start event to all players in the room
func _on_round_start(round_index, room_id):
	var room: Room = _room_dic[room_id]
	for player_id in room.get_players():
		room.get_players()[player_id].round_index = round_index
		Server.send_round_start_to_client(player_id, round_index)


# Sends the round end event to all players in the room
func _on_round_end(round_index, room_id):
	var room: Room = _room_dic[room_id]
	room.get_node("ActionManager").clear_action_instances()
	
	for player_id in room.get_players():
		Server.send_round_end_to_client(player_id, round_index)

func _on_capture_point_team_changed(team_id, capture_point, room_id):
	var room = _room_dic[room_id]
	var capturing_player_id = -1
	if team_id != -1:
		capturing_player_id = room.game_id_to_player_id[team_id]
	for player_id in room.get_players():
		Server.send_capture_point_team_changed(player_id, capturing_player_id, capture_point)


func _on_capture_point_captured(team_id, capture_point, room_id):
	var room = _room_dic[room_id]
	var capturing_player_id = -1
	if team_id != -1:
		capturing_player_id = room.game_id_to_player_id[team_id]
	for player_id in room.get_players():
		Server.send_capture_point_captured(player_id, capturing_player_id, capture_point)

func _on_capture_point_status_changed(capture_progress, team_id, capture_point, room_id):
	var room = _room_dic[room_id]
	var capturing_player_id = -1
	if team_id != -1:
		capturing_player_id = room.game_id_to_player_id[team_id]
	for player_id in room.get_players():
		Server.send_capture_point_status_changed(player_id, capturing_player_id, capture_point, capture_progress)

func _on_capture_point_capture_lost(team_id, capture_point, room_id):
	var room = _room_dic[room_id]
	var capturing_player_id = -1
	if team_id != -1:
		capturing_player_id = room.game_id_to_player_id[team_id]
	for player_id in room.get_players():
		Server.send_capture_point_capture_lost(player_id, capturing_player_id, capture_point)

func _on_game_result(team_id, room_id):
	var room = _room_dic[room_id]
	var winning_player_id = room.game_id_to_player_id[team_id]
	for player_id in room.get_players():
		Server.send_game_result(player_id, winning_player_id)
	room.reset()
	room.start_game()
