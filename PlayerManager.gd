extends Spatial


var _player_scene = preload("res://Players/Player.tscn")
var _enemy_scene = preload("res://Players/Enemy.tscn")

var player
var id
var enemies = {}

var time_of_last_world_state = -1
var time_since_last_server_update = 0


func _ready():
	Server.connect("spawning_player",self ,"spawn_player")
	Server.connect("spawning_enemy",self ,"spawn_enemy")
	Server.connect("despawning_enemy",self ,"despawn_enemy")
	Server.connect("world_state_received",self ,"update_enemy_positions")
	set_physics_process(false)


func _physics_process(delta):
	_define_player_state()


func _define_player_state():
	var player_state = {
		"T": Server.get_server_time(),
		"P": player.translation,
		"V": player.velocity,
		"A": player.acceleration,
		"R": player.rotation.y,
		"H": player.rotation_velocity
	}
	Server.send_player_state(player_state)


func spawn_player(player_id, spawn_point):
	set_physics_process(true)
	player = spawn_character(_player_scene,spawn_point)
	player.set_name(str(player_id))
	id = player_id


func spawn_enemy(enemy_id, spawn_point):
	var enemy = spawn_character(_enemy_scene,spawn_point)
	enemy.set_name(str(enemy_id))
	enemies[enemy_id]=enemy


func despawn_enemy(enemy_id):
	enemies[enemy_id].queue_free()
	enemies.erase(enemy_id)


func spawn_character(character_scene,spawn_point):
	var character = character_scene.instance()
	character.transform.origin = spawn_point
	add_child(character)
	return character


func update_enemy_positions(world_state):
	if time_of_last_world_state < world_state["T"]:
		time_of_last_world_state = world_state["T"]
		time_since_last_server_update = 0
		
		var enemy_states = world_state["S"]
		
		# deleting the own player 
		# TODO should also be adjusted to server state in case of cheating etc.
		# handle own player
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
		
		enemy.velocity = enemy.last_velocity + (enemy.server_velocity - enemy.last_velocity) * tick_progress
		
		var projected_from_start = enemy.last_position \
				+ enemy.velocity * time_since_last_server_update \
				+ enemy.server_acceleration * 0.5 * time_since_last_server_update * time_since_last_server_update
		
		var projected_from_last_known = enemy.server_position \
				+ enemy.server_velocity * time_since_last_server_update \
				+ enemy.server_acceleration * 0.5 * time_since_last_server_update * time_since_last_server_update
		
		enemy.transform.origin = projected_from_start \
				+ (projected_from_last_known - projected_from_start) * tick_progress
