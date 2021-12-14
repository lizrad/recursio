extends GhostManager

var _enemy_ghost_scene = preload("res://Characters/Ghost.tscn")
var _player_ghost_scene = preload("res://Characters/PlayerGhost.tscn")

# holds only the player ghosts
var _player_ghosts: Array = []
# holds only the enemy ghosts
var _enemy_ghosts: Array = []


# OVERRIDE #
func on_preparation_phase_started() -> void:
	.on_preparation_phase_started()
	_non_vfx_spawn_ghosts()
	_toggle_ghost_animation(false)
	_toggle_visbility_lights(false)
	# Display paths of my ghosts
	_update_ghost_paths()


# OVERRIDE #
func on_countdown_phase_started() -> void:
	.on_countdown_phase_started()
	# Delete ghost path visualization
	for ghost in _player_ghosts:
		ghost.delete_path()
	_toggle_ghost_animation(true)
	_visual_kill_ghosts()
	var countdown_phase_seconds = Constants.get_value("gameplay","countdown_phase_seconds")
	var spawn_time = Constants.get_value("gameplay","spawn_time")
	_visual_delay_spawn_ghosts(countdown_phase_seconds-spawn_time)


# OVERRIDE #
func on_game_phase_started() -> void:
	.on_game_phase_started()
	_toggle_visbility_lights(true)
	_toggle_ghost_animation(true)


# OVERRIDE #
func on_game_phase_stopped() -> void:
	.on_game_phase_stopped()


# OVERRIDE #
func _spawn_all_ghosts():
	for timeline_index in range(_max_ghosts+1):
		var player_id = _character_manager._player.player_id
		var team_id = _character_manager._player.team_id
		var spawn_point = _game_manager.get_spawn_point(team_id, timeline_index)
		var player_ghost = _create_ghost(player_id, team_id, timeline_index, spawn_point, _player_ghost_scene)
		_character_manager._apply_visibility_always(player_ghost)
		_player_ghosts.append(player_ghost)
		
		var enemy_id = _character_manager._enemy.player_id
		var enemy_team_id = abs(_character_manager._player.team_id-1)
		var enemy_spawn_point = _game_manager.get_spawn_point(enemy_team_id, timeline_index)
		var enemy_ghost = _create_ghost(enemy_id, enemy_team_id, timeline_index, enemy_spawn_point, _enemy_ghost_scene)
		
		_character_manager._apply_visibility_mask(enemy_ghost)
		_enemy_ghosts.append(enemy_ghost)
		
		_ghosts.append(player_ghost)
		_ghosts.append(enemy_ghost)


# OVERRIDE #
func _enable_active_ghosts() -> void:
	# Not calling super here because client and server have completely different concepts of ghost seperation - player/enemy and player[0]/player[1]
	for timeline_index in range(_max_ghosts+1):
		if timeline_index != _character_manager._player.timeline_index:
			if _player_ghosts[timeline_index].is_record_data_set():
				_player_ghosts[timeline_index].enable_body()
		
		if timeline_index != _character_manager._enemy.timeline_index:
			if _enemy_ghosts[timeline_index].is_record_data_set():
				_enemy_ghosts[timeline_index].enable_body()


# OVERRIDE #
func _use_new_record_data():
	# Not calling super because we dont want local values to overwrite remote ones
	# But we will use them until we get better ones
	var current_round_index = _round_manager.round_index-1
	var record_data = _character_manager._player.get_record_data()
	if current_round_index > _player_ghosts[record_data.timeline_index].round_index:
		_update_ghost_record(_player_ghosts, record_data.timeline_index, record_data, current_round_index)
		_player_ghosts[record_data.timeline_index].player_id = _character_manager._player.player_id
	
	record_data = _character_manager._enemy.get_record_data()
	if current_round_index > _enemy_ghosts[record_data.timeline_index].round_index:
		_update_ghost_record(_enemy_ghosts, record_data.timeline_index, record_data, current_round_index)
		_enemy_ghosts[record_data.timeline_index].player_id = _character_manager._enemy.player_id


# OVERRIDE #
func _on_ghost_hit(_perpetrator, _victim):
	# local ghost hits should not trigger anything on the client
	pass


# OVERRIDE #
func _refresh_previous_ghost_deaths():
	#again having to override this because of different concepts in charactermanager 
	var current_round_index = _round_manager.round_index
	_add_new_previous_ghost_deaths_data()
	var player = _character_manager._player
	var enemy  = _character_manager._enemy
	_clear_old_ghost_death_data(player.team_id, player.timeline_index, current_round_index)
	_clear_old_ghost_death_data(enemy.team_id, enemy.timeline_index, current_round_index)
	_current_ghost_death_index = 0
	_game_phase_start_time = _server.get_server_time()


func on_player_ghost_record_received(timeline_index, round_index,  record_data):
	_update_ghost_record(_player_ghosts, timeline_index, record_data , round_index)
	_update_ghost_paths()


func on_enemy_ghost_record_received(timeline_index,round_index,  record_data: RecordData):
	_update_ghost_record(_enemy_ghosts, timeline_index, record_data, round_index)


func on_ghost_hit_from_server(victim_player_id, victim_timeline_index, perpetrator_player_id, perpetrator_timeline_index) -> void:
	var ghost 
	if victim_player_id == _character_manager._player.player_id:
		ghost = _player_ghosts[victim_timeline_index]
		ghost.toggle_visibility_light(false)
	else:
		ghost = _enemy_ghosts[victim_timeline_index]
	var perpetrator = _find_perpetrator(perpetrator_player_id, perpetrator_timeline_index)
	ghost.server_hit(perpetrator)


func on_quiet_ghost_hit_from_server(victim_player_id, victim_timeline_index, perpetrator_player_id, perpetrator_timeline_index) -> void:
	#pretty much just the same code as with a normal hit (and nothing different should happen) but i used a different
	#function just in case we would want to react to it differently at a future date
	var ghost 
	if victim_player_id == _character_manager._player.player_id:
		ghost = _player_ghosts[victim_timeline_index]
		ghost.toggle_visibility_light(false)
	else:
		ghost = _enemy_ghosts[victim_timeline_index]
	var perpetrator = _find_perpetrator(perpetrator_player_id, perpetrator_timeline_index)
	ghost.quiet_hit(perpetrator)


func refresh_path_select():
	for ghost in _player_ghosts:
		ghost.toggle_path_select(false)
	_player_ghosts[_character_manager._player.timeline_index].toggle_path_select(true)


func _find_perpetrator(perpetrator_player_id, perpetrator_timeline_index):
	# First checking if it was one of the active players
	var player = _character_manager.get_player()
	var enemy = _character_manager.get_enemy()
	var player_team = (player.player_id == perpetrator_player_id)
	var active_perpetrator_player = player if player_team else enemy
	if active_perpetrator_player.timeline_index == perpetrator_player_id:
		return active_perpetrator_player
	
	# Now looking through the ghosts:
	var ghosts = _player_ghosts if player_team else _enemy_ghosts
	return ghosts[perpetrator_timeline_index]


func _toggle_visbility_lights(value: bool):
	for ghost in _player_ghosts:
		ghost.toggle_visibility_light(value)


func _update_ghost_paths():
	for ghost in _player_ghosts:
		if ghost.is_record_data_set():
			ghost.create_path()


func _toggle_ghost_animation(value) -> void:
	for ghost in _ghosts:
		ghost.toggle_animation(value)


func _visual_kill_ghosts() -> void:
	for ghost in _player_ghosts:
		ghost.visual_kill()
	# if ghosts are hidden we dont want to produce visible vfx here
	if not Constants.get_value("visibility","use_visibility"):
		for ghost in _enemy_ghosts:
			ghost.visual_kill()


func _visual_delay_spawn_ghosts(delay) -> void:
	for ghost in _player_ghosts:
		ghost.visual_delayed_spawn(delay)
	# if ghosts are hidden we dont want to produce visible vfx here
	if not Constants.get_value("visibility","use_visibility"):
		for ghost in _enemy_ghosts:
			ghost.visual_delayed_spawn(delay)


func _non_vfx_spawn_ghosts() -> void:
	for ghost in _ghosts:
		ghost.non_vfx_spawn()
