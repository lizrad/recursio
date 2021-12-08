extends Node
class_name GhostManager

signal ghost_hit(owning_player_id, timeline_index)
signal new_record_data_applied(player)

onready var Server = get_node("/root/Server")
var _ghost_scene = preload("res://Shared/Characters/GhostBase.tscn")

# Timeline index <-> ghost
# holds every ghost 
var _ghosts: Array = []
var _seperated_ghosts: Array = [[],[]]
var _max_ghosts = Constants.get_value("ghosts", "max_amount")

var _game_manager
var _round_manager
var _action_manager
var _character_manager

func init(game_manager,round_manager,action_manager, character_manager):
	_game_manager = game_manager
	_round_manager = round_manager
	_action_manager = action_manager
	_character_manager = character_manager
	_spawn_all_ghosts()
	_disable_all_ghosts()
	_move_ghosts_to_spawn()

func _spawn_all_ghosts():
	for timeline_index in range(_max_ghosts+1):
		for team_id  in [0,1]:
			var spawn_point = _game_manager.get_spawn_point(team_id, timeline_index)
			var player_id = _character_manager.team_id_to_player_id(team_id)
			print("PLAYER ID" + str(player_id))
			var ghost = _create_ghost(player_id, team_id, timeline_index, spawn_point, _ghost_scene)
			ghost.connect("hit", self, "_on_ghost_hit", [ghost])
			_seperated_ghosts[team_id].append(ghost)
			_ghosts.append(ghost)

func _create_ghost(player_id, team_id, timeline_index, spawn_point, ghost_scene):
	var ghost = ghost_scene.instance()
	add_child(ghost)
	ghost.init(_action_manager, player_id, team_id, timeline_index, spawn_point)
	return ghost

func _on_ghost_hit(ghost):
	Logger.info("Ghost hit!", "attacking")
	emit_signal("ghost_hit",ghost.player_id, ghost.timeline_index)

func _update_ghost_record(ghost_array, timeline_index, record_data):
	ghost_array[timeline_index].set_record_data(record_data)
	if _round_manager.get_current_phase() == RoundManager.Phases.GAME:
		ghost_array[timeline_index].round_index = _round_manager.round_index
	else:
		ghost_array[timeline_index].round_index = _round_manager.round_index-1
	refresh_active_ghosts()

func on_preparation_phase_started() -> void:
	_stop_ghosts()
	_move_ghosts_to_spawn()
	refresh_active_ghosts()

func on_countdown_phase_started() -> void:
	pass

func on_game_phase_started() -> void:
	_start_ghosts()

func on_game_phase_stopped() -> void:
	_use_new_record_data()

func _use_new_record_data():
	for player in _character_manager.player_dic.values():
		var record_data = player.get_record_data()
		_update_ghost_record(_seperated_ghosts[player.team_id], record_data.timeline_index, record_data)
		_seperated_ghosts[player.team_id][record_data.timeline_index].player_id = player.player_id
		emit_signal("new_record_data_applied", player)

func _move_ghosts_to_spawn() -> void:
	for ghost in _ghosts:
		ghost.move_to_spawn_point()

func refresh_active_ghosts():
	_disable_all_ghosts()
	_enable_active_ghosts()

func _enable_active_ghosts() -> void:
	for team_id in [0,1]:
		for timeline_index in range(0, _max_ghosts+1):
			var player_id = _character_manager.team_id_to_player_id(team_id)
			if timeline_index != _character_manager.player_dic[player_id].timeline_index:
				_seperated_ghosts[team_id][timeline_index].enable_body()

func _disable_all_ghosts() -> void:
	for ghost in _ghosts:
		ghost.disable_body()

func _start_ghosts() -> void:
	for ghost in _ghosts:
		ghost.start_playing(Server.get_server_time())
	
func _stop_ghosts() -> void:
	for ghost in _ghosts:
		ghost.stop_playing()




