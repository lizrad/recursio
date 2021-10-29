extends Node
class_name CharacterManager

onready var _action_manager: ActionManager = get_node("ActionManager")
onready var _game_manager: GameManager = get_node("GameManager")

# Scenes for instanciating 
var _player_scene = preload("res://Characters/Player.tscn")
var _ghost_scene = preload("res://Characters/Ghost.tscn")
var _player_ghost_scene = preload("res://Characters/PlayerGhost.tscn")
var _enemy_scene = preload("res://Characters/Enemy.tscn")

# Reference to player
var _player: Player
# Reference to enemy
var _enemy: Enemy

var _player_rpc_id: int

# Timeline index
var _player_ghosts: Array = []
var _enemy_ghosts: Array = []

var _max_ghosts = Constants.get_value("ghosts", "max_amount")

var _time_since_last_server_update = 0.0

func _ready():	
	# Connect to server signals
	assert(Server.connect("spawning_player", self, "_spawn_player") == OK)
	assert(Server.connect("spawning_enemy", self, "_spawn_enemy") == OK)
	assert(Server.connect("despawning_enemy", self, "_despawn_enemy") == OK)
	assert(Server.connect("world_state_received", self, "_update_character_positions") == OK)
	assert(Server.connect("own_ghost_record_received", self, "_create_own_ghost") == OK)
	assert(Server.connect("enemy_ghost_record_received", self, "_create_enemy_ghost") == OK)
	assert(Server.connect("player_hit", self, "_on_player_hit") == OK)
	assert(Server.connect("ghost_hit", self, "_on_ghost_hit") == OK)
	assert(Server.connect("timeline_picks", self, "_on_timeline_picks") == OK)
	assert(Server.connect("player_action", self, "_on_player_action") == OK)
	
	assert(Server.connect("round_start_received",self, "_on_round_start_received") == OK)
	assert(Server.connect("round_end_received", self, "_on_round_ended_received") == OK)
	assert(Server.connect("capture_point_captured", self, "_on_capture_point_captured") == OK)
	assert(Server.connect("capture_point_team_changed", self, "_on_capture_point_team_changed") == OK)
	assert(Server.connect("capture_point_status_changed", self, "_on_capture_point_status_changed") == OK)
	assert(Server.connect("capture_point_capture_lost", self, "_on_capture_point_capture_lost") == OK)
	assert(Server.connect("game_result", self, "_on_game_result") == OK)
	
	assert(InputManager.connect("player_timeline_picked", self, "_on_player_timeline_picked") == OK)
	
	assert(RoundManager.connect("round_started", self, "_on_round_started") == OK)
	assert(RoundManager.connect("latency_delay_phase_started", self, "_on_latency_delay_phase_started") == OK)
	assert(RoundManager.connect("preparation_phase_started", self, "_on_preparation_phase_started") == OK)
	assert(RoundManager.connect("countdown_phase_started", self, "_on_countdown_phase_started") == OK)
	assert(RoundManager.connect("game_phase_started", self, "_on_game_phase_started") == OK)

	_player_rpc_id = get_tree().get_network_unique_id()
	
	set_physics_process(false)


func _process(delta):
	
	_time_since_last_server_update += delta
	var server_delta = 1.0 / Server.tickrate

	# Goes from 0 to 1 for each network tick
	var tick_progress = _time_since_last_server_update / server_delta
	tick_progress = min(tick_progress, 1)

	# TODO: Use base move function?
	_enemy.velocity = (
		_enemy.last_velocity
		+ (_enemy.server_velocity - _enemy.last_velocity) * tick_progress
	)

	var projected_from_start = (
		_enemy.last_position
		+ _enemy.velocity * _time_since_last_server_update
		+ (
			_enemy.server_acceleration
			* 0.5
			* _time_since_last_server_update
			* _time_since_last_server_update
		)
	)

	var projected_from_last_known = (
		_enemy.server_position
		+ _enemy.server_velocity * _time_since_last_server_update
		+ (
			_enemy.server_acceleration
			* 0.5
			* _time_since_last_server_update
			* _time_since_last_server_update
		)
	)

	_enemy.transform.origin = (
		projected_from_start
		+ (projected_from_last_known - projected_from_start) * tick_progress
	)
	
	# Update CapturePoints in player HUD
	_player.update_capture_point_hud(_game_manager.get_capture_points())


func _reset() -> void:
	Logger.info("Full reset triggered.","gameplay")
	# Reset player
	_player.reset()
	_player.spawn_point = _game_manager.get_spawn_point(_player.team_id, 0)
	_player.move_to_spawn_point()
	# Reset enemy player
	_enemy.reset()
	_enemy.spawn_point = _game_manager.get_spawn_point(_enemy.team_id, 0)
	_enemy.move_to_spawn_point()
	# Reset player ghosts
	for timeline_index in _player_ghosts:
		_player_ghosts[timeline_index].queue_free()
	_player_ghosts.clear()
	# Reset enemy ghosts
	for timeline_index in _enemy_ghosts:
		_enemy_ghosts[timeline_index].queue_free()
	_enemy_ghosts.clear()
	
	_action_manager.clear_action_instances()


func _on_game_result(winning_player_index) -> void:
	if winning_player_index == _player_rpc_id:
		_game_manager.show_win()
	else:
		_game_manager.show_loss()


func _on_round_started(round_index, latency) -> void:
	_game_manager.hide_game_result_screen()
	_player.block_movement = false
	_player.show_round_start_hud(round_index, latency)
	
	# We have to disable this here because otherwise, the light never sees the ghosts for some reason
	_player.set_overview_light_enabled(false)


func _on_latency_delay_phase_started() -> void:
	_player.show_latency_delay_hud()


func _on_preparation_phase_started() -> void:
	_player.show_preparation_hud(RoundManager.round_index)
	
	# Display paths of my ghosts
	for timeline_index in _player_ghosts:
		var player_ghost: PlayerGhost = _player_ghosts[timeline_index]
		player_ghost.create_path()
	
	# Show player whole level
	_player.move_camera_to_overview()
	
	# Move player to next timeline spawn point
	var next_timeline_index = min(RoundManager.round_index - 1, _max_ghosts)
	_player.timeline_index = next_timeline_index
	_player.move_to_spawn_point()
	_enemy.timeline_index = next_timeline_index
	_enemy.move_to_spawn_point()
	
	# Add ghosts to scene and set their start position
	_enable_ghosts()
	_move_ghosts_to_spawn()


func _on_countdown_phase_started(countdown_time) -> void:
	# Delete ghost path visualization
	for timeline_index in _player_ghosts:
		_player_ghosts[timeline_index].delete_path()
	
	_player.follow_camera()
	_player.show_countdown_hud()
	_game_manager.show_countdown_screen(countdown_time)
	# Send currently selected timeline to server
	Server.send_timeline_pick(_player.timeline_index)

func _on_game_phase_started() -> void:
	_game_manager.hide_countdown_screen()
	_player.show_game_hud(RoundManager.round_index)
	_game_manager.toggle_capture_points(true)
	_start_ghosts()


func _on_round_ended():
	_player.block_movement = true
	_player.move_to_spawn_point()
	_stop_ghosts()
	_disable_ghosts()
	
	_game_manager.reset()
	_action_manager.clear_action_instances()


func _on_player_timeline_picked(timeline_index) -> void:
	_disable_ghosts()
	# Set player timeline
	_player.timeline_index = timeline_index
	# Enable new relevant ghosts
	_enable_ghosts()
	# Move player to new spawnpoint
	_player.move_to_spawn_point()


func _on_timeline_picks(timeline_index, enemy_pick):
	Logger.info("Received ghost picks from server","ghost_picking")
	_disable_ghosts()
	_player.timeline_index = timeline_index
	
	_player.swap_weapon_type(timeline_index)
	
	_enemy.timeline_index = enemy_pick
	_enable_ghosts()


func _start_ghosts() -> void:
	for timeline_id in _enemy_ghosts:
		_enemy_ghosts[timeline_id].start_playing(Server.get_server_time())
	for timeline_id in _player_ghosts:
		_player_ghosts[timeline_id].start_playing(Server.get_server_time())


func _stop_ghosts() -> void:
	for timeline_id in _enemy_ghosts:
		_enemy_ghosts[timeline_id].stop_playing()
	for timeline_id in _player_ghosts:
		_player_ghosts[timeline_id].stop_playing()


func _enable_ghosts() -> void:
	for timeline_index in _enemy_ghosts:
		var enemy_ghost = _enemy_ghosts[timeline_index]
		add_child(enemy_ghost)
		# Apply visibility for enemies
		_apply_visibility_mask(enemy_ghost)
	for timeline_index in _player_ghosts:
		# Skip if player is currently replacing this ghost
		if timeline_index == _player.timeline_index:
			continue
		var player_ghost = _player_ghosts[timeline_index]
		add_child(player_ghost)
		# Apply visibility for own ghosts (always visible)
		_apply_visibility_always(player_ghost)


func _disable_ghosts() -> void:
	for timeline_index in _enemy_ghosts:
		remove_child(_enemy_ghosts[timeline_index])
	for timeline_index in _player_ghosts:
		remove_child(_player_ghosts[timeline_index])


func _move_ghosts_to_spawn() -> void:
	for timeline_index in _enemy_ghosts:
		_enemy_ghosts[timeline_index].move_to_spawn_point()
	for timeline_index in _player_ghosts:
		_player_ghosts[timeline_index].move_to_spawn_point()


func _apply_visibility_mask(character) -> void:
	character.get_node("CharacterModel").set_shader_param("visibility_mask", _player.get_visibility_mask())
	if character.has_node("MiniMapIcon"):
		character.get_node("MiniMapIcon").visibility_mask = _player.get_visibility_mask()


func _apply_visibility_always(character) -> void:
	character.get_node("CharacterModel").set_shader_param("always_draw", true)









