extends Spatial

var _player_scene = preload("res://Players/Player.tscn")
var _ghost_scene = preload("res://Players/Ghost.tscn")
var _enemy_scene = preload("res://Players/Enemy.tscn")

var _my_ghosts = []
# Key: Player ID | Value: List of ghosts
var _enemy_ghosts_dic = {}

# The player reference
var player

# The player id (rpc id)
var id

var enemies = {}

var time_of_last_world_state = -1
var time_since_last_server_update = 0

var time_of_last_world_state_send = -1

export var level_path: NodePath
onready var level = get_node(level_path)

onready var _prep_phase_time: float = Constants.get_value("gameplay", "prep_phase_time")

func _ready():
	time_of_last_world_state_send = Server.get_server_time()

	Server.connect("spawning_player", self, "_spawn_player")
	Server.connect("spawning_enemy", self, "_spawn_enemy")
	Server.connect("despawning_enemy", self, "_despawn_enemy")
	Server.connect("world_state_received", self, "_update_enemy_positions")
	Server.connect("own_ghost_record_received", self, "_create_own_ghost")
	Server.connect("enemy_ghost_record_received", self, "_create_enemy_ghost")
	Server.connect("round_start_received",self, "_on_round_start_received")
	Server.connect("round_end_received", self, "_on_round_ended_received")
	Server.connect("capture_point_captured", self, "_on_capture_point_captured" )
	Server.connect("capture_point_team_changed", self, "_on_capture_point_team_changed" )
	Server.connect("capture_point_status_changed", self, "_on_capture_point_status_changed" )
	Server.connect("capture_point_capture_lost", self, "_on_capture_point_capture_lost" )
	Server.connect("game_result", self, "_on_game_result" )
	
	
	
	set_physics_process(false)

func _reset():
	player.reset()
	for enemy_id in enemies:
		enemies[enemy_id].reset()
	for ghost in _my_ghosts:
		ghost.queue_free()
	_my_ghosts.clear()
	for enemy_id in _enemy_ghosts_dic:
		for ghost in _enemy_ghosts_dic[enemy_id]:
			ghost.queue_free()
		_enemy_ghosts_dic[enemy_id].clear()
	_enemy_ghosts_dic.clear()
	time_of_last_world_state = -1
	time_since_last_server_update = 0
	time_of_last_world_state_send = -1

func _on_game_result(winning_player_id):
	var player_id = get_tree().get_network_unique_id()
	if winning_player_id == player_id:
		Logger.info("I won!", "gameplay")
	else:
		Logger.info("I lost!", "gameplay")
	#_reset()

func _on_capture_point_captured(capturing_player_id, capture_point):
	level.get_capture_points()[capture_point].capture(capturing_player_id)
	
func _on_capture_point_team_changed(capturing_player_id, capture_point):
	level.get_capture_points()[capture_point].set_capturing_player(capturing_player_id)
	
func _on_capture_point_status_changed(capturing_player_id, capture_point, capture_progress):
	level.get_capture_points()[capture_point].set_capture_status(capturing_player_id, capture_progress)
	
func _on_capture_point_capture_lost(capturing_player_id, capture_point):
	level.get_capture_points()[capture_point].capture_lost(capturing_player_id)


func _process(delta):
	time_since_last_server_update += delta
	var server_delta = 1.0 / Server.tickrate

	# Goes from 0 to 1 for each network tick
	var tick_progress = time_since_last_server_update / server_delta
	tick_progress = min(tick_progress, 1)

	for enemy in enemies.values():
		if not enemy.server_position:
			# No known server state yet
			continue

		enemy.velocity = (
			enemy.last_velocity
			+ (enemy.server_velocity - enemy.last_velocity) * tick_progress
		)

		var projected_from_start = (
			enemy.last_position
			+ enemy.velocity * time_since_last_server_update
			+ (
				enemy.server_acceleration
				* 0.5
				* time_since_last_server_update
				* time_since_last_server_update
			)
		)

		var projected_from_last_known = (
			enemy.server_position
			+ enemy.server_velocity * time_since_last_server_update
			+ (
				enemy.server_acceleration
				* 0.5
				* time_since_last_server_update
				* time_since_last_server_update
			)
		)

		enemy.transform.origin = (
			projected_from_start
			+ (projected_from_last_known - projected_from_start) * tick_progress
		)
	
	# Update capture points in HUD
	if player != null:
		var index: int = 0
		for capture_point in level.get_capture_points():
			player.hud.update_capture_point(index, capture_point.get_capture_progress(), capture_point.get_capture_team())
			index += 1



func _on_round_ended_received(round_index):
	_disable_ghosts()
	level.reset()
	level.toggle_capture_points(false)
	
func _on_round_start_received(round_index, latency_delay, server_time):
	player.hud.round_start(round_index, server_time)
	player.hud.prep_phase_start(round_index, server_time)
	Logger.info("Round "+str(round_index)+" started", "gameplay")
	var time_diff = (Server.get_server_time() - server_time)
	# Delay to counteract latency
	var delay = latency_delay - (time_diff  / 1000.0)
	Logger.debug("Time difference of "+str(time_diff/1000.0),"gameplay")
	# Wait for warm up
	yield(get_tree().create_timer(delay), "timeout")
	
	# Add ghosts to scene and set their start position
	_enable_ghosts()
	_move_ghosts_to_spawn()
	
	# Wait for preparation phase
	yield(get_tree().create_timer(_prep_phase_time), "timeout")
	Logger.info("Prep phase "+str(round_index)+" over", "gameplay")
	level.toggle_capture_points(true)
	player.hud.game_phase_start(round_index, Server.get_server_time())
	_restart_ghosts(Server.get_server_time())


func _apply_visibility_mask(character):
	if player:
		character.get_node("Mesh_Body").material_override.set_shader_param("visibility_mask", player.get_visibility_mask())
		character.get_node("Mesh_Body/Mesh_Eyes").material_override.set_shader_param("visibility_mask", player.get_visibility_mask())

func _create_enemy_ghost(enemy_id, gameplay_record):
	Logger.info("Enemy ("+str(enemy_id)+") ghost record received with start time of " + str(gameplay_record["T"]), "ghost")
	
	var ghost = _create_ghost(gameplay_record)
	ghost.add_to_group("Enemy")
	
	if _enemy_ghosts_dic[enemy_id].size()<=Constants.get_value("ghosts", "max_amount"):
		_enemy_ghosts_dic[enemy_id].append(ghost)
	else:
		var old_ghost = _enemy_ghosts_dic[enemy_id][gameplay_record["G"]]
		_enemy_ghosts_dic[enemy_id][gameplay_record["G"]] = ghost
		old_ghost.queue_free()
	
func _create_own_ghost(gameplay_record):
	Logger.info("Own ghost record received with start time of " + str(gameplay_record["T"]), "ghost")
	var ghost = _create_ghost(gameplay_record)
	ghost.add_to_group("Friend")
	if _my_ghosts.size()<=Constants.get_value("ghosts", "max_amount"):
		_my_ghosts.append(ghost)
	else:
		var old_ghost = _my_ghosts[gameplay_record["G"]]
		_my_ghosts[gameplay_record["G"]] = ghost
		old_ghost.queue_free()


func _create_ghost(gameplay_record):
	var ghost = _ghost_scene.instance()
	ghost.init(gameplay_record)
	return ghost

func _disable_ghosts()->void:
	for i in _enemy_ghosts_dic:
		for ghost in _enemy_ghosts_dic[i]:
			remove_child(ghost)
	for ghost in _my_ghosts:
		remove_child(ghost)


func _enable_ghosts() ->void:
	for i in _enemy_ghosts_dic:
		for ghost in _enemy_ghosts_dic[i]:
			# Apply the visibility mask for enemy ghosts only (friendly ones are always visible)
			_apply_visibility_mask(ghost)
			
			add_child(ghost)
	for ghost in _my_ghosts:
		add_child(ghost)


func _move_ghosts_to_spawn() -> void:
	for player_id in _enemy_ghosts_dic:
		for ghost in _enemy_ghosts_dic[player_id]:
			ghost.move_to_start_position()


func _restart_ghosts(start_time)->void:
	for i in _enemy_ghosts_dic:
		for ghost in _enemy_ghosts_dic[i]:
			ghost.start_replay(start_time)
	for ghost in _my_ghosts:
		ghost.start_replay(start_time)


func _physics_process(delta):
	_define_player_state()


var packet_id = 0


func _define_player_state():
	var player_state = {
		"T": time_of_last_world_state_send,
		"P": player.transform.origin,
		"V": player.velocity,
		"A": player.acceleration,
		"R": player.rotation.y,
		"H": player.rotation_velocity,
		"I": packet_id
	}
	Server.send_player_state(player_state)
	packet_id += 1
	#loop around so number does not grow uncontrolled
	#and because we only really need to know the difference
	#between 2 packets so it does not matter if ids dont
	#continually increase as long as we account for the loop
	#while calculating the difference on the server
	packet_id %= Constants.get_value("network", "max_packet_id")
	# This fixes sync issues - maybe because of unexpected order-of-execution of physics_process?
	time_of_last_world_state_send = Server.get_server_time()

func _reset_spawnpoints()->void:
	player.transform.origin = player.spawn_point

func _spawn_player(player_id, spawn_point):
	set_physics_process(true)
	player = _spawn_character(_player_scene, spawn_point)
	player.spawn_point = spawn_point
	player.set_name(str(player_id))
	id = player_id
	
	# Apply visibility mask to all entities which have been here before the player
	for enemy in enemies.values():
		_apply_visibility_mask(enemy)
	for ghosts in _enemy_ghosts_dic.values():
		for ghost in ghosts:
			_apply_visibility_mask(ghost)
	
	
	# Initialize capture point HUD for current level
	for i in range(level.get_capture_points().size()):
		player.hud.add_capture_point()
	
	# Update the player id for the HUD
	player.hud.set_player_id(player_id)


func _spawn_enemy(enemy_id, spawn_point):
	var enemy = _spawn_character(_enemy_scene, spawn_point)
	enemy.set_name(str(enemy_id))
	_apply_visibility_mask(enemy)
	enemies[enemy_id] = enemy
	_enemy_ghosts_dic[enemy_id] = []


func _despawn_enemy(enemy_id):
	enemies[enemy_id].queue_free()
	enemies.erase(enemy_id)
	for i in range(_enemy_ghosts_dic[enemy_id].size()):
		_enemy_ghosts_dic[enemy_id][i].queue_free()
	_enemy_ghosts_dic.erase(enemy_id)


func _spawn_character(character_scene, spawn_point):
	var character = character_scene.instance()
	character.transform.origin = spawn_point
	add_child(character)
	return character


func _update_enemy_positions(world_state):
	if time_of_last_world_state < world_state["T"]:
		time_of_last_world_state = world_state["T"]
		time_since_last_server_update = 0

		var enemy_states = world_state["S"]

		# Handle own player
		if enemy_states.has(id):
			var server_player = enemy_states[id]

			player.handle_network_update(server_player["P"], server_player["T"])

			enemy_states.erase(id)

		for enemy_id in enemy_states:
			if enemies.has(enemy_id):
				var enemy = enemies[enemy_id]

				# Set parameters for interpolation
				enemy.last_position = enemy.transform.origin
				enemy.last_velocity = enemy.velocity

				enemy.server_position = enemy_states[enemy_id]["P"]
				enemy.server_velocity = enemy_states[enemy_id]["V"]
				enemy.server_acceleration = enemy_states[enemy_id]["A"]


