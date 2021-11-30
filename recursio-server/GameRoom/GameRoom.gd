extends Viewport
class_name GameRoom

export(PackedScene) var game_room_world_scene
export(PackedScene) var level_scene
export(PackedScene) var capture_point_scene

signal world_state_updated(world_state, game_room_id)

var game_room_name: String
var id: int

onready var _server = get_node("/root/Server")

var _game_room_players_ready: Dictionary = {}
var _player_id_user_name_dic: Dictionary = {}

var _player_id_to_team_id = {}
var _team_id_to_player_id = {}

var _player_count: int = 0

var _player_levels_loaded := {}

var _game_room_world: GameRoomWorld
var _game_room_world_exists = false


func get_player_count():
	return _player_count


func get_game_room_world_exists():
	return _game_room_world_exists


func spawn_world():
	_game_room_world = game_room_world_scene.instance()
	self.add_child(_game_room_world)
	_game_room_world_exists = true
	var level = level_scene.instance()
	level.capture_point_scene = capture_point_scene
	_game_room_world.add_child(level)
	_game_room_world.set_level(level)
	
	var _error = _game_room_world.connect("world_state_updated", self, "_on_world_state_updated")
	_error = _game_room_world.get_game_manager().connect("capture_point_team_changed", self, "_on_capture_point_team_changed") 
	_error = _game_room_world.get_game_manager().connect("capture_point_captured", self, "_on_capture_point_captured") 
	_error = _game_room_world.get_game_manager().connect("capture_point_status_changed", self, "_on_capture_point_status_changed") 
	_error = _game_room_world.get_game_manager().connect("capture_point_capture_lost", self, "_on_capture_point_capture_lost") 
	_error = _game_room_world.get_game_manager().connect("game_result", self, "_on_game_result") 
	
	for player_id in _player_id_user_name_dic:
		var team_id = _player_id_to_team_id[player_id]
		var player_user_name = _player_id_user_name_dic[player_id]
		_game_room_world.spawn_player(player_id, team_id, player_user_name)
	
	var server_clock_warm_up = 3.0
	yield(get_tree().create_timer(server_clock_warm_up), "timeout")
	
	var game_warm_up = 1.0
	for player_id in _player_id_to_team_id:
		_server.send_game_start_to_client(player_id, _server.get_server_time()+game_warm_up*1000)
		
	yield(get_tree().create_timer(game_warm_up), "timeout")
	_game_room_world.start_game()


func despawn_world():
	_game_room_players_ready.clear()
	_game_room_world.queue_free()
	_player_levels_loaded.clear()
	_game_room_world_exists = false


func get_game_room_players() -> Dictionary:
	return _player_id_user_name_dic


func get_game_room_players_ready() -> Dictionary:
	return _game_room_players_ready


func add_player(player_id: int, player_user_name: String) -> void:
	_player_id_user_name_dic[player_id] = player_user_name
	# Update id dictionary
	_player_id_to_team_id[player_id] = _player_count
	_team_id_to_player_id[_player_count] = player_id
	_player_count += 1


func remove_player(player_id: int) -> void:
	# Update id dictionary
	if not _player_id_to_team_id.has(player_id):
		return
	var _success = _player_id_user_name_dic.erase(player_id)
	_success = _game_room_players_ready.erase(player_id)
	_success = _team_id_to_player_id.erase(_player_id_to_team_id[player_id])
	_success = _player_id_to_team_id.erase(player_id)
	_player_count -= 1
		
	var team_id = 0
	for player_id in _player_id_to_team_id:
		_player_id_to_team_id[player_id] = team_id
		_team_id_to_player_id[team_id] = player_id
		team_id += 1


func handle_game_room_ready(player_id):
	_game_room_players_ready[player_id] = true
	# Update on all clients
	for client_id in _player_id_user_name_dic:
		_server.send_game_room_ready(client_id, player_id)
	
	# If all players are ready, load level
	if _game_room_players_ready.keys().size() == Constants.PLAYER_MAX_COUNT:
		for client_id in _player_id_user_name_dic:
			_server.send_load_level(client_id)


func handle_game_room_not_ready(player_id):
	var _success = _game_room_players_ready.erase(player_id)
	# Update on all clients
	for client_id in _player_id_user_name_dic:
		_server.send_game_room_not_ready(client_id, player_id)


func handle_player_level_loaded(player_id):
	_player_levels_loaded[player_id] = true
	
	if _player_levels_loaded.size() == Constants.PLAYER_MAX_COUNT:
		spawn_world()


func update_player_input_data(player_id, input_data: InputData):
	if _game_room_world_exists:
		_game_room_world.update_player_input_data(player_id, input_data)


func handle_player_ready(player_id):
	if _game_room_world_exists:
		_game_room_world.handle_player_ready(player_id)


func handle_ghost_pick(player_id, timeline_index):
	if _game_room_world_exists:
		_game_room_world.handle_ghost_pick(player_id, timeline_index)


func _on_world_state_updated(world_state):
	emit_signal("world_state_updated", world_state, id)


##############################
####### Capture Points #######
##############################

func _on_capture_point_team_changed(team_id, capture_point):
	var capturing_player_id = -1
	if team_id != -1:
		capturing_player_id = _team_id_to_player_id[team_id]
	for player_id in _player_id_user_name_dic:
		_server.send_capture_point_team_changed(player_id, capturing_player_id, capture_point)


func _on_capture_point_captured(team_id, capture_point):
	var capturing_player_id = -1
	if team_id != -1:
		capturing_player_id = _team_id_to_player_id[team_id]
	for player_id in _player_id_user_name_dic:
		_server.send_capture_point_captured(player_id, capturing_player_id, capture_point)

func _on_capture_point_status_changed(capture_progress, team_id, capture_point):
	var capturing_player_id = -1
	if team_id != -1:
		capturing_player_id = _team_id_to_player_id[team_id]
	for player_id in _player_id_user_name_dic:
		_server.send_capture_point_status_changed(player_id, capturing_player_id, capture_point, capture_progress)

func _on_capture_point_capture_lost(team_id, capture_point):
	var capturing_player_id = -1
	if team_id != -1:
		capturing_player_id = _team_id_to_player_id[team_id]
	for player_id in _player_id_user_name_dic:
		_server.send_capture_point_capture_lost(player_id, capturing_player_id, capture_point)

func _on_game_result(team_id):
	var winning_player_id = _team_id_to_player_id[team_id]
	for player_id in _player_id_user_name_dic:
		_server.send_game_result(player_id, winning_player_id)
	
	yield(get_tree().create_timer(3), "timeout")
	despawn_world()
