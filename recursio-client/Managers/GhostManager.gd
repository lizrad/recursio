extends Node
class_name GhostManager

var _ghost_scene = preload("res://Characters/Ghost.tscn")
var _player_ghost_scene = preload("res://Characters/PlayerGhost.tscn")

# Timeline index <-> ghost
var _player_ghosts: Dictionary = {}
var _enemy_ghosts: Dictionary = {}

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
	for timeline_index in _enemy_ghosts:
		_apply_visibility_mask(_enemy_ghosts[timeline_index])

func _spawn_all_ghosts():
	pass

func _on_preparation_phase_started() -> void:
	_stop_ghosts()
	_toggle_visbility_lights(false)
	# Display paths of my ghosts
	_update_ghost_paths()
	# Add ghosts to scene and set their start position
	_move_ghosts_to_spawn()

func _on_countdown_phase_started() -> void:
	# Delete ghost path visualization
	for timeline_index in _player_ghosts:
		_player_ghosts[timeline_index].delete_path()
	_toggle_ghost_animation(true)
	_visual_kill_ghosts()
	var countdown_phase_seconds = Constants.get_value("gameplay","countdown_phase_seconds")
	var spawn_time = Constants.get_value("gameplay","spawn_time")
	_visual_delay_spawn_ghosts(countdown_phase_seconds-spawn_time)

func _on_game_phase_started() -> void:
	_disable_ghosts()
	_enable_ghosts()
	_toggle_visbility_lights(true)
	_start_ghosts()

func _toggle_visbility_lights(value: bool):
	for timeline_index in _player_ghosts:
		_player_ghosts[timeline_index].toggle_visibility_light(value)

func _on_player_timeline_changed(timeline_index) -> void:
	_disable_ghosts()
	_enable_ghosts()

func _on_timeline_picks(timeline_index, enemy_pick):
	# Free the ghosts that were at this position
	if _player_ghosts.has(timeline_index):
		_player_ghosts[timeline_index].queue_free()
		var _success = _player_ghosts.erase(timeline_index)
	
	if _enemy_ghosts.has(enemy_pick):
		_enemy_ghosts[enemy_pick].queue_free()
		var _success =_enemy_ghosts.erase(enemy_pick)

func _on_player_ghost_record_received(timeline_index, record_data):
	var ghost = _create_player_ghost(record_data)
	ghost.spawn_point = _game_manager.get_spawn_point(_character_manager._player.team_id, timeline_index)
	if _round_manager.get_current_phase() == RoundManager.Phases.GAME:
		ghost.round_index = _round_manager.round_index
	else:
		ghost.round_index = _round_manager.round_index - 1
	ghost.move_to_spawn_point()
	_player_ghosts[timeline_index] = ghost
	_update_ghost_paths()

func _update_ghost_paths():
	for timeline_index in _player_ghosts:
		var player_ghost: PlayerGhost = _player_ghosts[timeline_index]
		player_ghost.create_path()

func _on_enemy_ghost_record_received(timeline_index, record_data: RecordData):
	var ghost = _create_enemy_ghost(record_data)
	ghost.spawn_point = _game_manager.get_spawn_point(1 - _character_manager._player.team_id, timeline_index)
	if _round_manager.get_current_phase() == RoundManager.Phases.GAME:
		ghost.round_index = _round_manager.round_index
	else:
		ghost.round_index = _round_manager.round_index-1
	ghost.move_to_spawn_point()
	_enemy_ghosts[timeline_index] = ghost

func _on_ghost_hit(hit_ghost_player_owner, hit_ghost_id) -> void:
	if hit_ghost_player_owner == _character_manager._player.player_id:
		if _player_ghosts.has(hit_ghost_id):
			_player_ghosts[hit_ghost_id].server_hit()
	else:
		if _enemy_ghosts.has(hit_ghost_id):
			_enemy_ghosts[hit_ghost_id].server_hit()

func _create_player_ghost(record_data: RecordData):
	var ghost: PlayerGhost = _player_ghost_scene.instance()
	add_child(ghost)
	ghost.player_ghost_init(_action_manager, record_data)
	return ghost

func _create_enemy_ghost(record_data):
	var ghost: Ghost = _ghost_scene.instance()
	add_child(ghost)
	ghost.ghost_init(_action_manager, record_data)
	return ghost

func _visual_kill_ghosts() -> void:
	for timeline_id in _enemy_ghosts:
		_enemy_ghosts[timeline_id].visual_kill()
	for timeline_id in _player_ghosts:
		_player_ghosts[timeline_id].visual_kill()

func _toggle_ghost_animation(value) -> void:
	for timeline_id in _enemy_ghosts:
		_enemy_ghosts[timeline_id].toggle_animation(value)
	for timeline_id in _player_ghosts:
		_player_ghosts[timeline_id].toggle_animation(value)

func _visual_delay_spawn_ghosts(delay) -> void:
	for timeline_id in _enemy_ghosts:
		_enemy_ghosts[timeline_id].visual_delayed_spawn(delay)
	for timeline_id in _player_ghosts:
		_player_ghosts[timeline_id].visual_delayed_spawn(delay)

func _start_ghosts() -> void:
	for timeline_id in _enemy_ghosts:
		_enemy_ghosts[timeline_id].start_playing(Server.get_server_time())
		_enemy_ghosts[timeline_id].toggle_animation(true)
	for timeline_id in _player_ghosts:
		_player_ghosts[timeline_id].start_playing(Server.get_server_time())
		_player_ghosts[timeline_id].toggle_animation(true)

func _stop_ghosts() -> void:
	for timeline_id in _enemy_ghosts:
		_enemy_ghosts[timeline_id].stop_playing()
		_enemy_ghosts[timeline_id].toggle_animation(false)
	for timeline_id in _player_ghosts:
		_player_ghosts[timeline_id].stop_playing()
		_player_ghosts[timeline_id].toggle_animation(false)


func _enable_ghosts() -> void:
	for timeline_index in _enemy_ghosts:
		if timeline_index == _character_manager._enemy.timeline_index:
			continue
		var enemy_ghost = _enemy_ghosts[timeline_index]
		enemy_ghost.enable_body()
		# Apply visibility for enemies
		_apply_visibility_mask(enemy_ghost)
	for timeline_index in _player_ghosts:
		# Skip if player is currently replacing this ghost
		if timeline_index == _character_manager._player.timeline_index:
			_player_ghosts[timeline_index].toggle_path_select(true)
			continue
		var player_ghost = _player_ghosts[timeline_index]
		player_ghost.enable_body()
		# Apply visibility for own ghosts (always visible)
		_apply_visibility_always(player_ghost)

func _disable_ghosts() -> void:
	for timeline_index in _enemy_ghosts:
		_enemy_ghosts[timeline_index].disable_body()
	for timeline_index in _player_ghosts:
		_player_ghosts[timeline_index].disable_body()
		_player_ghosts[timeline_index].toggle_path_select(false)

func _move_ghosts_to_spawn() -> void:
	for timeline_index in _enemy_ghosts:
		_enemy_ghosts[timeline_index].move_to_spawn_point()
	for timeline_index in _player_ghosts:
		_player_ghosts[timeline_index].move_to_spawn_point()


func _apply_visibility_mask(character) -> void:
	if not _character_manager._player:
		return
	character.get_node("KinematicBody/CharacterModel").set_shader_param("visibility_mask", _character_manager._player.get_visibility_mask())
	if character.has_node("KinematicBody/MiniMapIcon"):
		character.get_node("KinematicBody/MiniMapIcon").visibility_mask = _character_manager._player.get_visibility_mask()


func _apply_visibility_always(character) -> void:
	character.get_node("KinematicBody/CharacterModel").set_shader_param("always_draw", true)
