extends GhostManager
class_name ServerGhostManager

var _ghost_scene = preload("res://Shared/Characters/GhostBase.tscn")


# holds ghosts split by team_id
var _seperated_ghosts: Array = [[],[]]


# previous deaths that could be relevant for current round
var _previous_ghost_deaths: Array = []
# deaths we recorded during the current round(will get added to above array after the round)
var _new_previous_ghost_death: Array = []
# previous deaths are ordered by time so we only ever have to check one index 
# and only after it's time has been reached, the following ones could be relevant
var _current_ghost_death_index = 0

var _raycast: RayCast

func _ready() -> void:
	_raycast = RayCast.new()
	_raycast.cast_to = Vector3(0,0, -Constants.get_value("hitscan", "range"))
	_raycast.enabled = false
	add_child(_raycast)


# OVERRIDE #
func on_game_phase_started() -> void:
	_refresh_previous_ghost_deaths()
	.on_game_phase_started()


# OVERRIDE #
func _update_ghosts(delta):
	_look_for_previous_death()
	._update_ghosts(delta)


# OVERRIDE ABSTRACT #
func _spawn_all_ghosts():
	for timeline_index in range(_max_ghosts+1):
		for team_id  in [0,1]:
			var spawn_point = _game_manager.get_spawn_point(team_id, timeline_index)
			var player_id = _character_manager.team_id_to_player_id(team_id)
			var ghost = _create_ghost(player_id, team_id, timeline_index, spawn_point, _ghost_scene)
			ghost.connect("hit", self, "_on_ghost_hit")
			_seperated_ghosts[team_id].append(ghost)
			_ghosts.append(ghost)


# OVERRIDE ABSTRACT #
func _enable_active_ghosts() -> void:
	for team_id in [0,1]:
		for timeline_index in range(0, _max_ghosts+1):
			var player_id = _character_manager.team_id_to_player_id(team_id)
			if timeline_index != _character_manager.player_dic[player_id].timeline_index:
				if _seperated_ghosts[team_id][timeline_index].is_record_data_set():
					_seperated_ghosts[team_id][timeline_index].enable_body()


# OVERRIDE ABSTRACT #
func _use_new_record_data():
	var current_round_index = _round_manager.round_index-1
	for player in _character_manager.player_dic.values():
		var record_data = player.get_record_data()
		_update_ghost_record(_seperated_ghosts[player.team_id], record_data.timeline_index, record_data, current_round_index)
		_seperated_ghosts[player.team_id][record_data.timeline_index].player_id = player.player_id
		emit_signal("new_record_data_applied", player)


# OVERRIDE ABSTRACT #
func _on_ghost_hit(hit_data: HitData):
	_new_previous_ghost_death.append(_create_new_ghost_death_data(hit_data))
	emit_signal("ghost_hit", hit_data)


func _on_player_killed(hit_data):
	#when an active player is killed we also have to create a ghost death so the death is fixed for the following rounds
	_new_previous_ghost_death.append(_create_new_ghost_death_data(hit_data))


func _is_ghost_active(team_id, round_index, timeline_index):
	var ghost = _seperated_ghosts[team_id][timeline_index]
	# check if ghost stored at timeline index was recorded for the passed round
	if ghost.round_index == round_index:
		return ghost.is_active() and ghost.is_playing()
	else:
		return false


func _refresh_previous_ghost_deaths():
	var current_round_index = _round_manager.round_index
	_add_new_previous_ghost_deaths_data()
	for player in _character_manager.player_dic.values():
		_clear_old_ghost_death_data(player.team_id, player.timeline_index, current_round_index)
	_current_ghost_death_index = 0


func _look_for_previous_death():
	if _round_manager.get_current_phase() != RoundManager.Phases.GAME:
		return
	if _current_ghost_death_index >= _previous_ghost_deaths.size():
		return
	var current_time = _server.get_server_time()-_game_phase_start_time
	while _previous_ghost_deaths[_current_ghost_death_index].time < current_time:
		_apply_previous_death(_previous_ghost_deaths[_current_ghost_death_index])
		_current_ghost_death_index+=1
		if _current_ghost_death_index >= _previous_ghost_deaths.size():
			break


func _apply_previous_death(death_data: DeathData):
	var hit_data = death_data.hit_data
	var victim_active = _is_ghost_active(hit_data.victim_team_id,hit_data.victim_round_index,hit_data.victim_timeline_index)
	var perpetrator_active = _is_ghost_active(hit_data.perpetrator_team_id,hit_data.perpetrator_round_index,hit_data.perpetrator_timeline_index)
	if victim_active and perpetrator_active:
		if _is_hit_unobstructed(hit_data):
			var victim = _seperated_ghosts[hit_data.victim_team_id][hit_data.victim_timeline_index]
			emit_signal("quiet_ghost_hit", hit_data)
			victim.quiet_hit(hit_data)

func _is_hit_unobstructed(hit_data: HitData):
	# Everthing except hitscan cannot be obstructred
	if not hit_data.type == HitData.HitType.HITSCAN:
		return true
	var unobstructed = true
	
	_raycast.clear_exceptions()
	_raycast.add_exception(_seperated_ghosts[hit_data.perpetrator_team_id][hit_data.perpetrator_timeline_index])
	_raycast.global_transform.origin = hit_data.position
	_raycast.rotation.y = hit_data.rotation
	_raycast.enabled = true
	_raycast.force_raycast_update()
	var collider = _raycast.get_collider()
	# Check if we hit a wall
	if collider is Wall:
		unobstructed = false
	# Check if we hit another character
	var character = collider.get_parent()
	if collider.get_parent() is CharacterBase:
		# at this point it is enough to just compare timeline index and team_id
		if character.timeline_index != hit_data.victim_timeline_index or character.team_id != hit_data.victim_team_id:
			unobstructed = false
	return unobstructed

func _clear_old_ghost_death_data(perpetrator_team_id, perpetrator_timeline_index, perpetrator_round_index):
	var to_remove = []
	for death_data in _previous_ghost_deaths:
		var hit_data = death_data.hit_data
		if hit_data.perpetrator_team_id == perpetrator_team_id and hit_data.perpetrator_timeline_index == perpetrator_timeline_index:
			if hit_data.perpetrator_round_index < perpetrator_round_index:
				to_remove.append(death_data)
	for death_data in to_remove:
		_previous_ghost_deaths.erase(death_data)


func _create_new_ghost_death_data(hit_data: HitData):
	var ghost_data = DeathData.new()
	
	ghost_data.time = _server.get_server_time()-_game_phase_start_time
	ghost_data.hit_data = hit_data
	return ghost_data


func _add_new_previous_ghost_deaths_data():
	_previous_ghost_deaths += _new_previous_ghost_death
	_new_previous_ghost_death.clear()
	_previous_ghost_deaths.sort_custom(self, "_costum_compare_ghost_death")


func _costum_compare_ghost_death(a, b):
	return a.time < b.time
