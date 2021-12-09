extends Node
class_name GhostManager

signal ghost_hit(owning_player_id, timeline_index)
signal quiet_ghost_hit(owning_player_id, timeline_index)
signal new_record_data_applied(player)

onready var Server = get_node("/root/Server")
var _ghost_scene = preload("res://Shared/Characters/GhostBase.tscn")

onready var _max_ghosts = Constants.get_value("ghosts", "max_amount")
# Timeline index <-> ghost
# holds every ghost 
var _ghosts: Array = []
var _seperated_ghosts: Array = [[],[]]

var _game_phase_start_time = -1
var _previous_ghost_deaths: Array = []
var _new_previous_ghost_death: Array = []
var _current_ghost_death_index = 0

var _game_manager
var _round_manager
var _action_manager
var _character_manager

func _ready():
	set_physics_process(false)

func _physics_process(delta):
	_look_for_previous_death()
	for ghost in _ghosts:
		ghost.update(delta)

func _look_for_previous_death():
	if _round_manager.get_current_phase() != RoundManager.Phases.GAME:
		return
	if _current_ghost_death_index >= _previous_ghost_deaths.size():
		return
	var current_time = Server.get_server_time()-_game_phase_start_time
	while _previous_ghost_deaths[_current_ghost_death_index].time < current_time:
		print("FOUND PREVIOUS DEATH AT TIME: "+str(_previous_ghost_deaths[_current_ghost_death_index].time))
		apply_previous_death(_previous_ghost_deaths[_current_ghost_death_index])
		_current_ghost_death_index+=1
		if _current_ghost_death_index >= _previous_ghost_deaths.size():
			break

func apply_previous_death(ghost_death_data):
	
	var victim_active = _is_ghost_active(ghost_death_data.victim_team_id,ghost_death_data.victim_round_index,ghost_death_data.victim_timeline_index)
	var perpetrator_active = _is_ghost_active(ghost_death_data.perpetrator_team_id,ghost_death_data.perpetrator_round_index,ghost_death_data.perpetrator_timeline_index)
	if victim_active and perpetrator_active:
		print("oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo")
		print("APPLYING GHOST DEATH DATA AT TIME: "+str(_previous_ghost_deaths[_current_ghost_death_index].time))
		print("   VICTIM: Team = "+str(ghost_death_data.victim_team_id)+" Round = "+str(ghost_death_data.victim_round_index)+" Timeline = "+str(ghost_death_data.victim_timeline_index))
		print("   PERPETRATOR: Team = "+str(ghost_death_data.perpetrator_team_id)+" Round = "+str(ghost_death_data.perpetrator_round_index)+" Timeline = "+str(ghost_death_data.perpetrator_timeline_index))
		print("oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo")
		var victim = _seperated_ghosts[ghost_death_data.victim_team_id][ghost_death_data.victim_timeline_index]
		var perpetrator = _seperated_ghosts[ghost_death_data.perpetrator_team_id][ghost_death_data.perpetrator_timeline_index]
		emit_signal("quiet_ghost_hit", victim.player_id, victim.timeline_index)
		victim.quiet_hit(perpetrator)


func _is_ghost_active(team_id, round_index, timeline_index):
	var ghost = _seperated_ghosts[team_id][timeline_index]
	if ghost.round_index == round_index:
		return ghost.is_active() and ghost.is_playing()
	else:
		return false

func init(game_manager,round_manager,action_manager, character_manager):
	_game_manager = game_manager
	_round_manager = round_manager
	_action_manager = action_manager
	_character_manager = character_manager
	set_physics_process(true)
	_spawn_all_ghosts()
	_disable_all_ghosts()
	_move_ghosts_to_spawn()

func _spawn_all_ghosts():
	for timeline_index in range(_max_ghosts+1):
		for team_id  in [0,1]:
			var spawn_point = _game_manager.get_spawn_point(team_id, timeline_index)
			var player_id = _character_manager.team_id_to_player_id(team_id)
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
	_new_previous_ghost_death.append(create_new_ghost_death_data(ghost, ghost.last_death_perpetrator))
	emit_signal("ghost_hit",ghost.player_id, ghost.timeline_index)

func _on_player_killed(victim, perpetrator):
	_new_previous_ghost_death.append(create_new_ghost_death_data(victim, perpetrator))

func create_new_ghost_death_data(victim, perpetrator):
	var ghost_data = GhostDeathData.new()
	
	ghost_data.time = Server.get_server_time()-_game_phase_start_time

	ghost_data.victim_team_id = victim.team_id
	ghost_data.victim_round_index = victim.round_index
	ghost_data.victim_timeline_index = victim.timeline_index

	ghost_data.perpetrator_team_id = perpetrator.team_id
	ghost_data.perpetrator_round_index = perpetrator.round_index
	ghost_data.perpetrator_timeline_index = perpetrator.timeline_index
	
	print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
	print("CREATED GHOST DEATH DATA AT TIME: "+str(ghost_data.time))
	print("   VICTIM: Team = "+str(victim.team_id)+" Round = "+str(victim.round_index)+" Timeline = "+str(victim.timeline_index))
	print("   PERPETRATOR: Round =  "+str(perpetrator.team_id)+" Round =  "+str(perpetrator.round_index)+" Timeline = "+str(perpetrator.timeline_index))
	print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
	return ghost_data

func _clear_old_ghost_death_data(perpetrator_team_id, perpetrator_timeline_index, perpetrator_round_index):
	var to_remove = []
	for data in _previous_ghost_deaths:
		if data.perpetrator_team_id == perpetrator_team_id and data.perpetrator_timeline_index == perpetrator_timeline_index:
			if data.perpetrator_round_index < perpetrator_round_index:
				to_remove.append(data)
	for data in to_remove:
		print("--------------------------------------------------------------")
		print("ERASED GHOST DEATH DATA At TIME: "+ str(data.time))
		print("   VICTIM: Team = "+str(data.victim_team_id)+" Round = "+str(data.victim_round_index)+" Timeline = "+str(data.victim_timeline_index))
		print("   PERPETRATOR: Round =  "+str(data.perpetrator_team_id)+" Round =  "+str(data.perpetrator_round_index)+" Timeline = "+str(data.perpetrator_timeline_index))
		print("--------------------------------------------------------------")
		_previous_ghost_deaths.erase(data)

func _update_ghost_record(ghost_array, timeline_index, record_data, round_index):
	ghost_array[timeline_index].set_record_data(record_data)
	ghost_array[timeline_index].round_index = round_index
	refresh_active_ghosts()

func on_preparation_phase_started() -> void:
	print("")
	print("==============================================================")
	print("                      PREP PHASE START")
	print("==============================================================")
	print("")
	refresh_active_ghosts()
	_stop_ghosts()
	_move_ghosts_to_spawn()

func on_countdown_phase_started() -> void:
	pass

func on_game_phase_started() -> void:
	_handle_previous_ghost_death_setup()
	_start_ghosts()

func _handle_previous_ghost_death_setup():
	var current_round_index = _round_manager.round_index
	_add_new_previous_ghost_death_data()
	for player in _character_manager.player_dic.values():
		_clear_old_ghost_death_data(player.team_id, player.timeline_index, current_round_index)
	_current_ghost_death_index = 0
	_game_phase_start_time = Server.get_server_time()

func on_game_phase_stopped() -> void:
	_use_new_record_data()

func _add_new_previous_ghost_death_data():
	_previous_ghost_deaths += _new_previous_ghost_death
	_new_previous_ghost_death.clear()
	_previous_ghost_deaths.sort_custom(self, "_costum_compare_ghost_death")

func _costum_compare_ghost_death(a, b):
	return a.time < b.time

func _use_new_record_data():
	var current_round_index = _round_manager.round_index-1
	for player in _character_manager.player_dic.values():
		var record_data = player.get_record_data()
		_update_ghost_record(_seperated_ghosts[player.team_id], record_data.timeline_index, record_data, current_round_index)
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
