extends Node
class_name GameRoomWorld

signal world_state_updated(world_state)

onready var _server = get_node("/root/Server")
onready var _character_manager: CharacterManager = get_node("CharacterManager")
onready var _ghost_manager: CharacterManager = get_node("GhostManager")
onready var _world_state_manager: WorldStateManager = get_node("WorldStateManager")
onready var _game_manager: GameManager = get_node("GameManager")
onready var _action_manager: ActionManager = get_node("ActionManager")
onready var _round_manager: RoundManager = get_node("RoundManager")


# track players ready -> skip prep phase if all player are
var _players_ready = {}


# We don't process the latest player data, but the latest data which was sent in world_processing_offset or earlier.
# That way, we avoid discrepancies between high- and low-latency players and don't need to rollback.
# TODO: Could be set dynamically by using someting like max(player_pings)
var world_processing_offset = 50


func _ready():
	var _error = _character_manager.connect("world_state_updated", self, "_on_world_state_update") 	
	
	_error = _round_manager.connect("preparation_phase_started", self,"_on_preparation_phase_started")
	_error = _round_manager.connect("countdown_phase_started", self,"_on_countdown_phase_started")
	_error = _round_manager.connect("game_phase_started", self,"_on_game_phase_started") 
	_error = _round_manager.connect("game_phase_stopped", self,"_on_game_phase_stopped") 
	
	_world_state_manager.world_processing_offset = world_processing_offset
	_character_manager.world_processing_offset = world_processing_offset


func set_level(level: Node):
	_game_manager._level = level


func start_game():
	_game_manager.start_game()
	_round_manager.future_start_game(_server.get_server_time())


func spawn_player(player_id: int, team_id: int, player_user_name: String) -> void:
	_character_manager.spawn_player(player_id, team_id, player_user_name)


func update_player_input_data(player_id, input_data: InputData):
	if _round_manager.get_current_phase() == RoundManager.Phases.GAME:
		_character_manager.update_player_input_data(player_id, input_data)


func handle_player_ready(player_id):
	_players_ready[player_id] = true
	Logger.info("received player ready for player " + str(player_id) + " count: " + str(_players_ready.keys().size()), "game_rooms")
	if _players_ready.keys().size() == Constants.PLAYER_MAX_COUNT:
		var time_until_switch = 0.5
		if _round_manager.get_current_phase_time_left()>time_until_switch and _round_manager.get_current_phase() == RoundManager.Phases.PREPARATION:
			var countdown_start_time = _server.get_server_time()+time_until_switch
			_round_manager.future_switch_to_phase(RoundManager.Phases.COUNTDOWN,countdown_start_time)
			for client_id in _players_ready:
				_server.send_phase_switch_to_client(client_id, _round_manager.round_index, RoundManager.Phases.COUNTDOWN, countdown_start_time)


func handle_ghost_pick(player_id, timeline_index):
	if _round_manager.get_current_phase() != RoundManager.Phases.COUNTDOWN:
		Logger.error("Received timeline picks outside proper phase", "ghost_picking")
		return
	_character_manager.set_timeline_index(player_id, timeline_index)
	_ghost_manager.refresh_active_ghosts()


func get_players():
	return _character_manager.player_dic


func get_game_manager() -> GameManager:
	return _game_manager


func get_round_manager() -> RoundManager:
	return _round_manager


func _on_world_state_update(world_state):
	if _round_manager.get_current_phase() == RoundManager.Phases.GAME:
		emit_signal("world_state_updated", world_state)


func _on_preparation_phase_started():
	var round_index = _round_manager.round_index
	var switch_time = _round_manager.get_deadline()
	var default_timeline_index = min(round_index,Constants.get_value("ghosts", "max_amount"))
	for player_id in _character_manager.player_dic:
		_character_manager.player_dic[player_id].round_index = round_index
		_character_manager.player_dic[player_id].reset_record_data()
		_character_manager.set_timeline_index(player_id, default_timeline_index)
		_ghost_manager.refresh_active_ghosts()
		_server.send_phase_switch_to_client(player_id, round_index, RoundManager.Phases.COUNTDOWN, switch_time)
	

func _on_countdown_phase_started():
	var round_index = _round_manager.round_index
	var switch_time = _round_manager.get_deadline()
	for player_id in _character_manager.player_dic:
		_server.send_phase_switch_to_client(player_id, round_index, RoundManager.Phases.GAME, switch_time)
	
func _on_game_phase_started() -> void:
	var round_index = _round_manager.round_index
	var switch_time = _round_manager.get_deadline()
	for player_id in _character_manager.player_dic:
		_server.send_phase_switch_to_client(player_id, round_index, RoundManager.Phases.PREPARATION, switch_time)
	_character_manager.propagate_player_picks()
	_character_manager.enable_ghosts()
	_character_manager.start_ghosts()
	_character_manager.move_players_to_spawn_point()
	_character_manager.set_block_player_input(false)


func _on_game_phase_stopped():
	_action_manager.clear_action_instances()
	_ghost_manager.handle_active_player_records()
	_character_manager.disable_ghosts()
	_character_manager.stop_ghosts()
	_character_manager.reset_wall_indices()
	_character_manager.move_players_to_spawn_point()
	_character_manager.set_block_player_input(true)
	_game_manager.reset()
	_players_ready.clear()

