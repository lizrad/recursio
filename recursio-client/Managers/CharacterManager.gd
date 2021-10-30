extends Node
class_name CharacterManager

onready var _action_manager: ActionManager = get_node("ActionManager")
onready var _game_manager: GameManager = get_node("GameManager")
onready var _round_manager: RoundManager = get_node("RoundManager")

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

# Timeline index <-> ghost
var _player_ghosts: Dictionary = {}
var _enemy_ghosts: Dictionary = {}

var _max_ghosts = Constants.get_value("ghosts", "max_amount")

var _time_since_last_server_update = 0.0
var _time_since_last_world_state_update = 0.0

func _ready():
	assert(Server.connect("round_started", self, "_on_server_round_started") == OK)
	assert(Server.connect("round_ended", self, "_on_server_round_ended") == OK)
	
	assert(_round_manager.connect("round_started", self, "_on_round_started") == OK)
	assert(_round_manager.connect("latency_delay_phase_started", self, "_on_latency_delay_phase_started") == OK)
	assert(_round_manager.connect("preparation_phase_started", self, "_on_preparation_phase_started") == OK)
	assert(_round_manager.connect("countdown_phase_started", self, "_on_countdown_phase_started") == OK)
	assert(_round_manager.connect("game_phase_started", self, "_on_game_phase_started") == OK)
	
	assert(InputManager.connect("player_timeline_picked", self, "_on_player_timeline_picked") == OK)
	
	# Connect to server signals
	assert(Server.connect("spawning_player", self, "_on_spawn_player") == OK)
	assert(Server.connect("spawning_enemy", self, "_on_spawn_enemy") == OK)
	assert(Server.connect("despawning_enemy", self, "_on_despawn_enemy") == OK)
	assert(Server.connect("player_ghost_record_received", self, "_on_player_ghost_record_received") == OK)
	assert(Server.connect("enemy_ghost_record_received", self, "_create_enemy_ghost") == OK)
	
	assert(Server.connect("world_state_received", self, "_on_world_state_received") == OK)
	assert(Server.connect("player_hit", self, "_on_player_hit") == OK)
	assert(Server.connect("ghost_hit", self, "_on_ghost_hit") == OK)
	
	assert(Server.connect("timeline_picks", self, "_on_timeline_picks") == OK)
	
	assert(Server.connect("capture_point_captured", self, "_on_capture_point_captured") == OK)
	assert(Server.connect("capture_point_capture_lost", self, "_on_capture_point_capture_lost") == OK)
	
	assert(Server.connect("game_result", self, "_on_game_result") == OK)
	
	

	_player_rpc_id = get_tree().get_network_unique_id()
	
	set_physics_process(false)


func _process(delta):
	if not _round_manager.round_is_running():
		return
	
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


func _on_server_round_started(round_index, server_time) -> void:
	_round_manager.start_round(round_index, (Server.get_server_time() - server_time) / 1000.0)


func _on_server_round_ended(round_index) -> void:
	_round_manager.stop_round()


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
	_player.show_preparation_hud(_round_manager.round_index)
	
	# Display paths of my ghosts
	for timeline_index in _player_ghosts:
		var player_ghost: PlayerGhost = _player_ghosts[timeline_index]
		player_ghost.create_path()
	
	# Show player whole level
	_player.move_camera_to_overview()
	
	# Move player to next timeline spawn point
	var next_timeline_index = min(_round_manager.round_index - 1, _max_ghosts)
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
	_player.show_game_hud(_round_manager.round_index)
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


func _on_player_ready(_button) -> void:
	Server.send_player_ready()


func _on_player_ghost_record_received(timeline_index, record_data):
	var ghost = _create_player_ghost(record_data)
	ghost.spawn_point = _game_manager.get_spawn_point(_player.team_id, timeline_index)
	
	if _player_ghosts.has(timeline_index):
		_player_ghosts[timeline_index] .queue_free()
	_player_ghosts[timeline_index] = ghost


func _on_enemy_ghost_record_received(timeline_index, record_data: RecordData):	
	var ghost = _create_enemy_ghost(record_data)
	ghost.spawn_point = _game_manager.get_spawn_points(1 - _player.team_id, timeline_index)
	
	# Check if there is already a ghost, and delete it
	if _enemy_ghosts.has(timeline_index):
		_enemy_ghosts[timeline_index].queue_free()
	_enemy_ghosts[timeline_index] = ghost


func _on_spawn_player(player_id, spawn_point, team_id):
	set_physics_process(true)
	_player = _spawn_character(_player_scene, spawn_point)
	assert(_player.button_overlay.connect("button_pressed", self, "_on_player_ready") == OK)
	_player_rpc_id = player_id
	_player.team_id = team_id
	_player.set_name(str(player_id))
	
	# Apply visibility mask to all entities which have been here before the player
	_apply_visibility_mask(_enemy)
	for timeline_index in _enemy_ghosts:
		_apply_visibility_mask(_enemy_ghosts[timeline_index])
	
	# Initialize capture point HUD for current level
	_player.setup_capture_point_hud(_game_manager.get_capture_points().size())


func _on_spawn_enemy(enemy_id, spawn_point):
	_enemy = _spawn_character(_enemy_scene, spawn_point)
	_enemy.set_name(str(enemy_id))
	_apply_visibility_mask(_enemy)


func _on_despawn_enemy(enemy_id):
	_enemy.queue_free()
	for timeline_index in _enemy_ghosts:
		_enemy_ghosts[timeline_index].queue_free()
	_enemy_ghosts.clear()


func _on_world_state_received(world_state: WorldState):
	if _time_since_last_world_state_update < world_state.timestamp:
		_time_since_last_world_state_update = world_state.timestamp
		_time_since_last_server_update = 0

		var player_states: Dictionary = world_state.player_states

		
		if player_states.has(_player_rpc_id):
			var server_player: PlayerState = player_states[_player_rpc_id]

			_player.handle_server_update(server_player.position, server_player.timestamp)

			player_states.erase(_player_rpc_id)

		for id in player_states:
			# Handle own player
			if id == _player_rpc_id:
				var server_player: PlayerState = player_states[_player_rpc_id]
				_player.handle_server_update(server_player.position, server_player.timestamp)
				player_states.erase(_player_rpc_id)
			else:
				# Set parameters for interpolation
				_enemy.last_position = _enemy.transform.origin
				_enemy.last_velocity = _enemy.velocity
				_enemy.rotation.y = player_states[id].rotation
				_enemy.server_position = player_states[id].position
				_enemy.server_velocity = player_states[id].velocity
				_enemy.server_acceleration = player_states[id].acceleration


func _on_player_hit(hit_player_id) -> void:
	_player.hit() if hit_player_id == _player_rpc_id else _enemy.hit()


func _on_ghost_hit(hit_ghost_player_owner, hit_ghost_id) -> void:
	if hit_ghost_player_owner == _player_rpc_id:
		_player_ghosts[hit_ghost_id].hit()
	else:
		_enemy_ghosts[hit_ghost_id].hit()


func _on_capture_point_captured(capturing_player_id, capture_point):
	if capturing_player_id == _player_rpc_id:
		_player.move_camera_to_overview()
		_player.set_overview_light_enabled(true)


func _on_capture_point_capture_lost(capturing_player_id, capture_point):
	if capturing_player_id == _player_rpc_id:
		_player.follow_camera()
		_player.set_overview_light_enabled(false)


func _spawn_character(character_scene, spawn_point):
	var character: CharacterBase = character_scene.instance()
	character.spawn_point = spawn_point
	character.move_to_spawn_point()
	add_child(character)
	return character


func _create_player_ghost(record_data: RecordData):
	var ghost: PlayerGhost = _player_ghost_scene.instance()
	# TODO: Get color from ColorManager
	ghost.player_ghost_init(_action_manager, record_data, Color.lightcoral)
	return ghost


func _create_enemy_ghost(record_data):
	var ghost: Ghost = _ghost_scene.instance()
	# TODO: Get color from ColorManager
	ghost.ghost_init(_action_manager, record_data, Color.lightblue)
	return ghost


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









