extends Node
class_name GhostManager

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
			var ghost = _create_ghost(timeline_index, _ghost_scene)
			ghost.spawn_point = _game_manager.get_spawn_point(team_id, timeline_index)
			_seperated_ghosts[team_id].append(ghost)
			_ghosts.append(ghost)

func _create_ghost(timeline_index, ghost_scene):
	var ghost = ghost_scene.instance()
	add_child(ghost)
	ghost.init(_action_manager, timeline_index)
	return ghost

func _update_ghost_record(ghost_array, timeline_index, record_data):
	ghost_array[timeline_index].set_record_data(record_data)
	if _round_manager.get_current_phase() == RoundManager.Phases.GAME:
		ghost_array[timeline_index].round_index = _round_manager.round_index
	else:
		ghost_array[timeline_index].round_index = _round_manager.round_index-1
	refresh_active_ghosts()

func _on_preparation_phase_started() -> void:
	_stop_ghosts()
	_move_ghosts_to_spawn()

func _on_countdown_phase_started() -> void:
	pass

func _on_game_phase_started() -> void:
	_start_ghosts()


func _move_ghosts_to_spawn() -> void:
	
	for ghost in _ghosts:
		ghost.move_to_spawn_point()

func refresh_active_ghosts():
	_disable_all_ghosts()
	_enable_active_ghosts()

func _enable_active_ghosts() -> void:
	#TODO: Implement this for the server
	pass

func _disable_all_ghosts() -> void:
	for ghost in _ghosts:
		ghost.disable_body()

func _start_ghosts() -> void:
	for ghost in _ghosts:
		ghost.start_playing(Server.get_server_time())
	
func _stop_ghosts() -> void:
	for ghost in _ghosts:
		ghost.stop_playing()




