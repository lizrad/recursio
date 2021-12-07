extends Node
class_name GhostManager

var _ghost_scene = preload("res://Characters/Ghost.tscn")
var _player_ghost_scene = preload("res://Characters/PlayerGhost.tscn")

# Timeline index <-> ghost 
var _player_ghosts: Array = []
var _enemy_ghosts: Array = []

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
	_disable_ghosts()
	_move_ghosts_to_spawn()

func _spawn_all_ghosts():
	for timeline_index in range(_max_ghosts+1):
		_player_ghosts.append(_create_ghost(timeline_index, _player_ghost_scene))
		_player_ghosts[timeline_index].spawn_point = _game_manager.get_spawn_point(_character_manager._player.team_id, timeline_index)
		_enemy_ghosts.append(_create_ghost(timeline_index, _ghost_scene))
		_enemy_ghosts[timeline_index].spawn_point = _game_manager.get_spawn_point(_character_manager._player.team_id-1, timeline_index)
		_apply_visibility_mask(_enemy_ghosts[timeline_index])

func _create_ghost(timeline_index, ghost_scene):
	var ghost = ghost_scene.instance()
	add_child(ghost)
	ghost.init(_action_manager, timeline_index)
	return ghost

func _on_player_ghost_record_received(timeline_index, record_data):
	_player_ghosts[timeline_index].set_record_data(record_data)
	if _round_manager.get_current_phase() == RoundManager.Phases.GAME:
		_player_ghosts[timeline_index].round_index = _round_manager.round_index
	else:
		_player_ghosts[timeline_index].round_index = _round_manager.round_index - 1
	_update_ghost_paths()

func _on_enemy_ghost_record_received(timeline_index, record_data: RecordData):
	_enemy_ghosts[timeline_index].set_record_data(record_data)
	if _round_manager.get_current_phase() == RoundManager.Phases.GAME:
		_enemy_ghosts[timeline_index].round_index = _round_manager.round_index
	else:
		_enemy_ghosts[timeline_index].round_index = _round_manager.round_index-1

func _on_preparation_phase_started() -> void:
	_stop_ghosts()
	_toggle_visbility_lights(false)
	# Display paths of my ghosts
	_update_ghost_paths()
	# Add ghosts to scene and set their start position
	_move_ghosts_to_spawn()

func _on_countdown_phase_started() -> void:
	# Delete ghost path visualization
	for ghost in _player_ghosts:
		ghost.delete_path()
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
	for ghost in _player_ghosts:
		ghost.toggle_visibility_light(value)

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



func _update_ghost_paths():
	for ghost in _player_ghosts:
		ghost.create_path()

func _on_ghost_hit(hit_ghost_player_owner, hit_ghost_id) -> void:
	if hit_ghost_player_owner == _character_manager._player.player_id:
		if _player_ghosts.has(hit_ghost_id):
			_player_ghosts[hit_ghost_id].server_hit()
	else:
		if _enemy_ghosts.has(hit_ghost_id):
			_enemy_ghosts[hit_ghost_id].server_hit()



func _visual_kill_ghosts() -> void:
	for ghost in _enemy_ghosts:
		ghost.visual_kill()
	for ghost in _player_ghosts:
		ghost.visual_kill()

func _toggle_ghost_animation(value) -> void:
	for ghost in _enemy_ghosts:
		ghost.toggle_animation(value)
	for ghost in _player_ghosts:
		ghost.toggle_animation(value)

func _visual_delay_spawn_ghosts(delay) -> void:
	for ghost in _enemy_ghosts:
		ghost.visual_delayed_spawn(delay)
	for ghost in _player_ghosts:
		ghost.visual_delayed_spawn(delay)

func _start_ghosts() -> void:
	for ghost in _enemy_ghosts:
		ghost.start_playing(Server.get_server_time())
		ghost.toggle_animation(true)
	for ghost in _player_ghosts:
		ghost.start_playing(Server.get_server_time())
		ghost.toggle_animation(true)

func _stop_ghosts() -> void:
	for ghost in _enemy_ghosts:
		ghost.stop_playing()
		ghost.toggle_animation(false)
	for ghost in _player_ghosts:
		ghost.stop_playing()
		ghost.toggle_animation(false)


func _enable_ghosts() -> void:
	for timeline_index in range(_enemy_ghosts.size()):
		if timeline_index == _character_manager._enemy.timeline_index:
			continue
		var enemy_ghost = _enemy_ghosts[timeline_index]
		enemy_ghost.enable_body()
		# Apply visibility for enemies
		_apply_visibility_mask(enemy_ghost)
	for timeline_index in range(_player_ghosts.size()):
		# Skip if player is currently replacing this ghost
		if timeline_index == _character_manager._player.timeline_index:
			_player_ghosts[timeline_index].toggle_path_select(true)
			continue
		var player_ghost = _player_ghosts[timeline_index]
		player_ghost.enable_body()
		# Apply visibility for own ghosts (always visible)
		_apply_visibility_always(player_ghost)

func _disable_ghosts() -> void:
	for ghost in _enemy_ghosts:
		ghost.disable_body()
	for ghost in _player_ghosts:
		ghost.disable_body()
		ghost.toggle_path_select(false)

func _move_ghosts_to_spawn() -> void:
	for ghost in _enemy_ghosts:
		ghost.move_to_spawn_point()
	for ghost in _player_ghosts:
		ghost.move_to_spawn_point()


func _apply_visibility_mask(character) -> void:
	if not _character_manager._player:
		return
	character.get_node("KinematicBody/CharacterModel").set_shader_param("visibility_mask", _character_manager._player.get_visibility_mask())
	if character.has_node("KinematicBody/MiniMapIcon"):
		character.get_node("KinematicBody/MiniMapIcon").visibility_mask = _character_manager._player.get_visibility_mask()


func _apply_visibility_always(character) -> void:
	character.get_node("KinematicBody/CharacterModel").set_shader_param("always_draw", true)
