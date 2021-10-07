extends Spatial

var _player_scene = preload("res://Players/Player.tscn")
var _ghost_scene = preload("res://Players/Ghost.tscn")
var _enemy_scene = preload("res://Players/Enemy.tscn")
var _my_ghosts = []
var _enemy_ghosts = {}

var player
var id
var enemies = {}

var time_of_last_world_state = -1
var time_since_last_server_update = 0

var time_of_last_world_state_send = -1


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
	set_physics_process(false)

func _on_round_ended_received(round_index):
	_disable_ghosts()
	
func _on_round_start_received(round_index, warm_up, server_time):
	var time_diff = (Server.get_server_time() - server_time)
	# Delay to counteract latency
	var warm_up_with_delay = warm_up - (time_diff  / 1000.0)
	# Wait for warm up
	yield(get_tree().create_timer(warm_up_with_delay), "timeout")
	_enable_ghosts()
	_restart_ghosts(server_time)

func _create_enemy_ghost(enemy_id, gameplay_record):
	Logger.info("Enemy ("+str(enemy_id)+") ghost record received with start time of " + str(gameplay_record["T"]), "ghost")
	var ghost = _create_ghost(gameplay_record)
	if _enemy_ghosts[enemy_id].size()<=2:
		_enemy_ghosts[enemy_id].append(ghost)
	else:
		var old_ghost = _enemy_ghosts[enemy_id][gameplay_record["G"]]
		_enemy_ghosts[enemy_id][gameplay_record["G"]] = ghost
		old_ghost.queue_free()
	
func _create_own_ghost(gameplay_record):
	Logger.info("Own ghost record received with start time of " + str(gameplay_record["T"]), "ghost")
	var ghost = _create_ghost(gameplay_record)
	if _my_ghosts.size()<=2:
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
	for i in _enemy_ghosts:
		for ghost in _enemy_ghosts[i]:
			remove_child(ghost)
	for ghost in _my_ghosts:
		remove_child(ghost)


func _enable_ghosts() ->void:
	for i in _enemy_ghosts:
		for ghost in _enemy_ghosts[i]:
			add_child(ghost)
	for ghost in _my_ghosts:
		add_child(ghost)


func _restart_ghosts(start_time)->void:
	for i in _enemy_ghosts:
		for ghost in _enemy_ghosts[i]:
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


func _spawn_enemy(enemy_id, spawn_point):
	var enemy = _spawn_character(_enemy_scene, spawn_point)
	enemy.set_name(str(enemy_id))
	enemies[enemy_id] = enemy
	_enemy_ghosts[enemy_id] = []


func _despawn_enemy(enemy_id):
	enemies[enemy_id].queue_free()
	enemies.erase(enemy_id)
	for i in range(_enemy_ghosts[enemy_id].size()):
		_enemy_ghosts[enemy_id][i].queue_free()
	_enemy_ghosts.erase(enemy_id)


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
