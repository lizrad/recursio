extends Node
class_name CharacterManager

signal game_started()

onready var _action_manager: ActionManager = get_node("ActionManager")
onready var _game_manager: GameManager = get_node("GameManager")
onready var _round_manager: RoundManager = get_node("RoundManager")

onready var _random_names = TextFileToArray.load_text_file("res://Resources/Data/animal_names.txt")

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
var _player_user_name: String

# Timeline index <-> ghost
var _player_ghosts: Dictionary = {}
var _enemy_ghosts: Dictionary = {}

var _max_ghosts = Constants.get_value("ghosts", "max_amount")

var _time_since_last_server_update = 0.0
var _time_since_last_world_state_update = 0.0

func _ready():
	var _error = Server.connect("phase_switch_received", self, "_on_phase_switch_received") 
	_error = Server.connect("game_start_received", self, "_on_game_start_received") 

	_error = _round_manager.connect("preparation_phase_started", self, "_on_preparation_phase_started") 
	_error = _round_manager.connect("countdown_phase_started", self, "_on_countdown_phase_started") 
	_error = _round_manager.connect("game_phase_started", self, "_on_game_phase_started") 

	# Connect to server signals
	_error = Server.connect("spawning_player", self, "_on_spawn_player") 
	_error = Server.connect("spawning_enemy", self, "_on_spawn_enemy") 
	_error = Server.connect("despawning_enemy", self, "_on_despawn_enemy") 
	_error = Server.connect("player_ghost_record_received", self, "_on_player_ghost_record_received") 
	_error = Server.connect("enemy_ghost_record_received", self, "_on_enemy_ghost_record_received") 

	_error = Server.connect("world_state_received", self, "_on_world_state_received") 
	_error = Server.connect("player_hit", self, "_on_player_hit") 
	_error = Server.connect("ghost_hit", self, "_on_ghost_hit") 

	_error = Server.connect("timeline_picks", self, "_on_timeline_picks") 

	_error = Server.connect("capture_point_captured", self, "_on_capture_point_captured") 
	_error = Server.connect("capture_point_capture_lost", self, "_on_capture_point_capture_lost")
	
	_error = Server.connect("game_result", self, "_on_game_result")


	_player_rpc_id = get_tree().get_network_unique_id()
	randomize()
	var random_index = randi() % _random_names.size()
	_player_user_name = _random_names[random_index]
	set_physics_process(false)


func _physics_process(delta):
	if not _round_manager.is_running():
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

	_enemy.position = (
		projected_from_start
		+ (projected_from_last_known - projected_from_start) * tick_progress
	)

	_enemy.trigger_actions(_enemy.last_triggers)
	_enemy.last_triggers = 0

	# Update CapturePoints in player HUD
	_player.update_capture_point_hud(_game_manager.get_capture_points())


func _reset() -> void:
	Logger.info("Full reset triggered.", "gameplay")
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


func _on_game_start_received(start_time):
	_round_manager.future_start_game(start_time)


func get_player_user_name() -> String:
	return _player_user_name


func get_player_id() -> int:
	return _player_rpc_id


func _on_phase_switch_received(round_index, next_phase, switch_time):
	_round_manager.round_index = round_index
	_round_manager.get_previous_phase(next_phase)
	_round_manager.future_switch_to_phase(next_phase, switch_time)


func _on_preparation_phase_started() -> void:
	_player.block_movement = true
	_player.clear_walls()
	_player.clear_past_frames()
	_player.move_to_spawn_point()
	_stop_ghosts()

	_toggle_visbility_lights(false)
	_game_manager.reset()
	_action_manager.clear_action_instances()
	_game_manager.hide_game_result_screen()
	_player.show_preparation_hud(_round_manager.round_index)
	
	# Display paths of my ghosts
	_update_ghost_paths()
	
	# Show player whole level
	_player.move_camera_to_overview()
	
	# Move player to next timeline spawn point
	var next_timeline_index = min(_round_manager.round_index, _max_ghosts)
	_player.timeline_index = next_timeline_index
	_enemy.timeline_index = next_timeline_index
	_enemy.move_to_spawn_point()
	# Add ghosts to scene and set their start position
	_move_ghosts_to_spawn()


func _on_countdown_phase_started() -> void:
	# Delete ghost path visualization
	for timeline_index in _player_ghosts:
		_player_ghosts[timeline_index].delete_path()
	_player.follow_camera()
	_player.show_countdown_hud()
	_game_manager.show_countdown_screen()
	# Send currently selected timeline to server
	Server.send_timeline_pick(_player.timeline_index)


func _on_game_phase_started() -> void:
	_player.block_movement = false
	_player.set_overview_light_enabled(false)
	_disable_ghosts()
	_enable_ghosts()
	_toggle_visbility_lights(true)
	_game_manager.hide_countdown_screen()
	_player.show_game_hud(_round_manager.round_index)
	_game_manager.toggle_capture_points(true)
	_start_ghosts()


func _on_game_result(winning_player_index) -> void:
	if winning_player_index == _player_rpc_id:
		_game_manager.show_win()
	else:
		_game_manager.show_loss()


func _on_player_timeline_changed(timeline_index) -> void:
	_disable_ghosts()
	_player.spawn_point = _game_manager.get_spawn_point(_player.team_id, timeline_index)
	_player.move_to_spawn_point()
	_enable_ghosts()

func _on_timeline_picks(timeline_index, enemy_pick):
	Logger.info("Received ghost picks from server","ghost_picking")
	_player.timeline_index = timeline_index
	_enemy.timeline_index = enemy_pick
	
	# Free the ghosts that were at this position
	if _player_ghosts.has(timeline_index):
		_player_ghosts[timeline_index].queue_free()
		var _success = _player_ghosts.erase(timeline_index)
	
	if _enemy_ghosts.has(enemy_pick):
		_enemy_ghosts[enemy_pick].queue_free()
		var _success =_enemy_ghosts.erase(enemy_pick)


func _on_player_ready(button) -> void:
	if button == ButtonOverlay.BUTTONS.DOWN:
		Server.send_player_ready()


func _on_player_ghost_record_received(timeline_index, record_data):
	var ghost = _create_player_ghost(record_data)
	ghost.spawn_point = _game_manager.get_spawn_point(_player.team_id, timeline_index)
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
	ghost.spawn_point = _game_manager.get_spawn_point(1 - _player.team_id, timeline_index)
	if _round_manager.get_current_phase() == RoundManager.Phases.GAME:
		ghost.round_index = _round_manager.round_index
	else:
		ghost.round_index = _round_manager.round_index-1
	ghost.move_to_spawn_point()
	_enemy_ghosts[timeline_index] = ghost


func _on_spawn_player(player_id, spawn_point, team_id):
	set_physics_process(true)
	_player = _spawn_character(_player_scene, spawn_point)
	_player.player_init(_action_manager, _round_manager)
	# TODO: Tunnel signal instead of accessing button overlay here
	var _error = _player.get_button_overlay().connect("button_pressed", self, "_on_player_ready") 
	_player_rpc_id = player_id
	_player.team_id = team_id
	_player.player_id = player_id
	_player.set_name(str(player_id))
	_game_manager.set_team_id(team_id)
	# Apply visibility mask to all entities which have been here before the player
	_apply_visibility_always(_player)
	for timeline_index in _enemy_ghosts:
		_apply_visibility_mask(_enemy_ghosts[timeline_index])
	if _enemy: _apply_visibility_mask(_enemy)
	
	# Initialize capture point HUD for current level
	_player.setup_capture_point_hud(_game_manager.get_capture_points().size())
	
	_error = _player.connect("timeline_index_changed", self, "_on_player_timeline_changed") 
	_error = Server.connect("wall_spawn", _player, "_on_wall_spawn_received") 
	
	_player.user_name = _player_user_name
	emit_signal("game_started")

func _on_spawn_enemy(enemy_id, spawn_point):
	_enemy = _spawn_character(_enemy_scene, spawn_point)
	_enemy.enemy_init(_action_manager)
	_enemy.set_name(str(enemy_id))
	_apply_visibility_mask(_enemy)


func _on_despawn_enemy():
	_enemy.queue_free()
	for timeline_index in _enemy_ghosts:
		_enemy_ghosts[timeline_index].queue_free()
	_enemy_ghosts.clear()


func _on_world_state_received(world_state: WorldState):
	if _time_since_last_world_state_update < world_state.timestamp:
		_time_since_last_world_state_update = world_state.timestamp
		_time_since_last_server_update = 0

		if not _player: 
			return

		var player_states: Dictionary = world_state.player_states
		if player_states.has(_player_rpc_id):
			var server_player: PlayerState = player_states[_player_rpc_id]
			_player.handle_server_update(server_player.position, server_player.timestamp)
			var _success = player_states.erase(_player_rpc_id)

		for id in player_states:
			# Handle own player
			if id == _player_rpc_id:
				var server_player: PlayerState = player_states[_player_rpc_id]
				_player.handle_server_update(server_player.position, server_player.timestamp)
				var _success = player_states.erase(_player_rpc_id)
			else:
				# Set parameters for interpolation
				_enemy.last_position = _enemy.position
				_enemy.last_velocity = _enemy.velocity
				_enemy.rotation_y = player_states[id].rotation_y
				_enemy.server_position = player_states[id].position
				_enemy.server_velocity = player_states[id].velocity
				_enemy.server_acceleration = player_states[id].acceleration
				_enemy.last_triggers |= player_states[id].buttons


func _on_player_hit(hit_player_id) -> void:
	if hit_player_id == _player_rpc_id:
		_player.server_hit() 
	else:
		 _enemy.server_hit()


func _on_ghost_hit(hit_ghost_player_owner, hit_ghost_id) -> void:
	if hit_ghost_player_owner == _player_rpc_id:
		_player_ghosts[hit_ghost_id].server_hit()
	else:
		_enemy_ghosts[hit_ghost_id].server_hit()


func _on_capture_point_captured(capturing_player_id, _capture_point):
	if capturing_player_id == _player_rpc_id:
		_player.move_camera_to_overview()
		_player.set_overview_light_enabled(true)


func _on_capture_point_capture_lost(capturing_player_id, _capture_point):
	if capturing_player_id == _player_rpc_id:
		_player.follow_camera()
		_player.set_overview_light_enabled(false)


func _spawn_character(character_scene, spawn_point):
	var character: CharacterBase = character_scene.instance()
	add_child(character)
	character.spawn_point = spawn_point
	character.move_to_spawn_point()
	return character


func _create_player_ghost(record_data: RecordData):
	var ghost: PlayerGhost = _player_ghost_scene.instance()
	add_child(ghost)
	# TODO: Get color from ColorManager
	ghost.player_ghost_init(_action_manager, record_data)
	return ghost


func _create_enemy_ghost(record_data):
	var ghost: Ghost = _ghost_scene.instance()
	add_child(ghost)
	# TODO: Get color from ColorManager
	ghost.ghost_init(_action_manager, record_data)
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
		if timeline_index == _enemy.timeline_index:
			continue
		var enemy_ghost = _enemy_ghosts[timeline_index]
		enemy_ghost.enable_body()
		# Apply visibility for enemies
		_apply_visibility_mask(enemy_ghost)
	for timeline_index in _player_ghosts:
		# Skip if player is currently replacing this ghost
		if timeline_index == _player.timeline_index:
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


func _toggle_visbility_lights(value: bool):
	_player.toggle_visibility_light(value)
	for timeline_index in _player_ghosts:
		_player_ghosts[timeline_index].toggle_visibility_light(value)


func _move_ghosts_to_spawn() -> void:
	for timeline_index in _enemy_ghosts:
		_enemy_ghosts[timeline_index].move_to_spawn_point()
	for timeline_index in _player_ghosts:
		_player_ghosts[timeline_index].move_to_spawn_point()


func _apply_visibility_mask(character) -> void:
	if not _player:
		return

	character.get_node("KinematicBody/CharacterModel").set_shader_param("visibility_mask", _player.get_visibility_mask())
	if character.has_node("KinematicBody/MiniMapIcon"):
		character.get_node("KinematicBody/MiniMapIcon").visibility_mask = _player.get_visibility_mask()


func _apply_visibility_always(character) -> void:
	character.get_node("KinematicBody/CharacterModel").set_shader_param("always_draw", true)









