extends Viewport
class_name Room

# Connects all the specific managers together

signal world_state_updated(world_state, room_id)
signal room_filled()
signal phase_started(phase)

const PLAYER_NUMBER_PER_ROOM = 2

var room_name: String
var id: int
var player_count: int = 0

onready var _character_manager: CharacterManager = get_node("CharacterManager")
onready var _world_state_manager: WorldStateManager = get_node("WorldStateManager")
onready var _game_manager: GameManager = get_node("GameManager")
onready var _action_manager: ActionManager = get_node("ActionManager")
onready var _round_manager: RoundManager = get_node("RoundManager")
onready var _level = get_node("LevelH") # TODO: Should be configurable later

# id dictionary -> translates network id to game id (0 or 1)
var _player_id_to_team_id = {}
var team_id_to_player_id = {}

# track players ready -> skip prep phase if all player are
var _players_ready = {}

# We don't process the latest player data, but the latest data which was sent in world_processing_offset or earlier.
# That way, we avoid discrepancies between high- and low-latency players and don't need to rollback.
# TODO: Could be set dynamically by using someting like max(player_pings)
var world_processing_offset = 50


func _ready():
	_character_manager.connect("world_state_updated", self, "_on_world_state_update") 	
	
	_round_manager.connect("round_started", self,"_on_round_started") 
	_round_manager.connect("game_phase_started", self,"_on_game_phase_started") 
	_round_manager.connect("game_phase_ended", self,"_on_game_phase_ended") 
	
	_game_manager._level = _level
	_world_state_manager.world_processing_offset = world_processing_offset
	_character_manager.world_processing_offset = world_processing_offset


func reset():
	Logger.info("Full reset triggered.","gameplay")
	_action_manager.clear_action_instances()
	_character_manager.reset()
	_game_manager.reset()
	_level.reset()


func add_player(player_id: int) -> void:
	_character_manager.spawn_player(player_id, player_count)
	#update id dictionary
	_player_id_to_team_id[player_id] = player_count
	team_id_to_player_id[player_count] = player_id
	player_count += 1

	# If the room is filled, start the game
	if player_count >= PLAYER_NUMBER_PER_ROOM:
		start_game()


func start_game():
	_game_manager.start_game()
	yield(get_tree().create_timer(3), "timeout")
	_round_manager.start_round(0, 0)


func remove_player(player_id: int) -> void:
	_character_manager.despawn_player(player_id)
	#update id dictionary
	_player_id_to_team_id.erase(player_id)
	team_id_to_player_id.clear()
	var team_id = 0
	for player_id in _player_id_to_team_id:
		_character_manager.player_dic[player_id].team_id = team_id
		_player_id_to_team_id[player_id] = team_id
		team_id_to_player_id[team_id] = player_id
		team_id += 1

	player_count -= 1


func update_player_input_data(player_id, input_data: InputData):
	if _round_manager.get_current_phase() == RoundManager.Phases.GAME:
		_character_manager.update_player_input_data(player_id, input_data)


func handle_player_ready(player_id):
	_players_ready[player_id] = true
	Logger.info("received player ready for player " + str(player_id) + " count: " + str(_players_ready.keys().size()), "rooms")
	if _players_ready.keys().size() == PLAYER_NUMBER_PER_ROOM:
		# TODO: remove or fix, this is evil! >:-D
		# !!!
		_round_manager._timer = Constants.get_value("gameplay", "prep_phase_time")
		emit_signal("phase_started", RoundManager.Phases.COUNTDOWN)


func handle_ghost_pick(player_id, timeline_index):
	if _round_manager.get_current_phase() != RoundManager.Phases.COUNTDOWN:
		Logger.error("Received ghost picks outside proper phase", "ghost_picking")
		return

	_character_manager.set_timeline_index(player_id, timeline_index)


func get_players():
	return _character_manager.player_dic


func get_game_manager() -> GameManager:
	return _game_manager


func get_round_manager() -> RoundManager:
	return _round_manager


func _on_world_state_update(world_state):
	if _round_manager.get_current_phase() == RoundManager.Phases.GAME:
		emit_signal("world_state_updated", world_state, id)


func _on_round_started(round_index, latency):
	var default_timeline_index = min(round_index,Constants.get_value("ghosts", "max_amount"))
	for player_id in _character_manager.player_dic:
		_character_manager.set_timeline_index(player_id, default_timeline_index)


func _on_game_phase_started(latency) -> void:
	_character_manager.propagate_player_picks()
	_character_manager.enable_ghosts()
	_character_manager.start_ghosts()
	_character_manager.move_players_to_spawn_point()
	_character_manager.set_block_player_input(false)


func _on_game_phase_ended() -> void:
	_round_manager.stop_round()


func end_round(round_index) -> void:
	_character_manager.create_ghosts()
	_character_manager.disable_ghosts()
	_character_manager.stop_ghosts()
	_character_manager.reset_wall_indices()
	_character_manager.move_players_to_spawn_point()
	_character_manager.set_block_player_input(true)
	_game_manager.reset()

	_players_ready.clear()
