extends GhostManager

var _enemy_ghost_scene = preload("res://Characters/Ghost.tscn")
var _player_ghost_scene = preload("res://Characters/PlayerGhost.tscn")
# holds only the player ghosts
var _player_ghosts: Array = []
# holds only the enemy ghosts
var _enemy_ghosts: Array = []

var _newest_server_record = -1
var _newest_client_record = -1

# OVERRIDE #
func _spawn_all_ghosts():
	for timeline_index in range(_max_ghosts+1):
		var player_ghost = _create_ghost(timeline_index, _player_ghost_scene)
		player_ghost.spawn_point = _game_manager.get_spawn_point(_character_manager._player.team_id, timeline_index)
		_apply_visibility_always(player_ghost)
		_player_ghosts.append(player_ghost)
		
		var enemy_ghost = _create_ghost(timeline_index, _enemy_ghost_scene)
		enemy_ghost.spawn_point = _game_manager.get_spawn_point(abs(_character_manager._player.team_id-1), timeline_index)
		_apply_visibility_mask(enemy_ghost)
		_enemy_ghosts.append(enemy_ghost)
		
		_ghosts.append(player_ghost)
		_ghosts.append(enemy_ghost)

# OVERRIDE #
func _on_preparation_phase_started() -> void:
	._on_preparation_phase_started()
	_toggle_ghost_animation(false)
	_toggle_visbility_lights(false)
	# Display paths of my ghosts
	_update_ghost_paths()

# OVERRIDE #
func _on_countdown_phase_started() -> void:
	._on_countdown_phase_started()
	# Delete ghost path visualization
	for ghost in _player_ghosts:
		ghost.delete_path()
	_toggle_ghost_animation(true)
	_visual_kill_ghosts()
	var countdown_phase_seconds = Constants.get_value("gameplay","countdown_phase_seconds")
	var spawn_time = Constants.get_value("gameplay","spawn_time")
	_visual_delay_spawn_ghosts(countdown_phase_seconds-spawn_time)

# OVERRIDE #
func _on_game_phase_started() -> void:
	._on_game_phase_started()
	_toggle_visbility_lights(true)
	_toggle_ghost_animation(true)

# OVERRIDE #
func _enable_active_ghosts() -> void:
	# Not calling super here because client and server have completely different concepts of ghost seperation - player/enemy and player1/player2
	for timeline_index in range(_max_ghosts+1):
		if timeline_index != _character_manager._player.timeline_index:
			_player_ghosts[timeline_index].enable_body()
		
		if timeline_index != _character_manager._enemy.timeline_index:
			_enemy_ghosts[timeline_index].enable_body()

func _on_player_ghost_record_received(timeline_index, record_data):
	_update_ghost_record(_player_ghosts, timeline_index, record_data)
	_update_ghost_paths()

func _on_enemy_ghost_record_received(timeline_index, record_data: RecordData):
	_update_ghost_record(_enemy_ghosts, timeline_index, record_data)


func _on_ghost_hit_from_server(hit_ghost_player_owner, hit_ghost_id) -> void:
	if hit_ghost_player_owner == _character_manager._player.player_id:
		_player_ghosts[hit_ghost_id].server_hit()
	else:
		_enemy_ghosts[hit_ghost_id].server_hit()

func _toggle_visbility_lights(value: bool):
	for ghost in _player_ghosts:
		ghost.toggle_visibility_light(value)


func _update_ghost_paths():
	for ghost in _player_ghosts:
		ghost.create_path()

func _visual_kill_ghosts() -> void:
	for ghost in _ghosts:
		ghost.visual_kill()

func _toggle_ghost_animation(value) -> void:
	for ghost in _ghosts:
		ghost.toggle_animation(value)

func _visual_delay_spawn_ghosts(delay) -> void:
	for ghost in _ghosts:
		ghost.visual_delayed_spawn(delay)

func refresh_path_select():
	for ghost in _player_ghosts:
		ghost.toggle_path_select(false)
	_player_ghosts[_character_manager._player.timeline_index].toggle_path_select(true)

func _apply_visibility_mask(character) -> void:
	character.get_node("KinematicBody/CharacterModel").set_shader_param("visibility_mask", _character_manager._player.get_visibility_mask())
	if character.has_node("KinematicBody/MiniMapIcon"):
		character.get_node("KinematicBody/MiniMapIcon").visibility_mask = _character_manager._player.get_visibility_mask()

func _apply_visibility_always(character) -> void:
	character.get_node("KinematicBody/CharacterModel").set_shader_param("always_draw", true)
