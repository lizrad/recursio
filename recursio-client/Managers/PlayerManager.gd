extends Spatial



var time_of_last_world_state = -1
var time_since_last_server_update = 0

var time_of_last_world_state_send = -1



func _on_player_ready(_button) -> void:
	Server.send_player_ready()


func _create_enemy_ghost(enemy_id, gameplay_record):
	Logger.info("Enemy ("+str(enemy_id)+") ghost record received with start time of " + str(gameplay_record["T"]), "ghost")
	
	var ghost = _create_ghost(gameplay_record)
	#Low Priority TODO: this works for two player only
	ghost.spawn_point = _get_spawn_point(1-player.team_id,gameplay_record["G"])
	ghost.add_to_group("Enemy")
	if _enemy_ghosts_dic[enemy_id].has([gameplay_record["G"]]):
		_enemy_ghosts_dic[enemy_id][gameplay_record["G"]].queue_free()
	_enemy_ghosts_dic[enemy_id][gameplay_record["G"]] = ghost
	
func _create_own_ghost(gameplay_record):
	Logger.info("Own ghost record received with start time of " + str(gameplay_record["T"]), "ghost")
	var ghost = _create_ghost(gameplay_record, true)
	ghost.spawn_point = _get_spawn_point(player.team_id,gameplay_record["G"])
	ghost.add_to_group("Friend")
	if _my_ghosts.has([gameplay_record["G"]]):
		_my_ghosts[gameplay_record["G"]] .queue_free()
	_my_ghosts[gameplay_record["G"]] = ghost

func _create_ghost(gameplay_record, friendly = false):
	var ghost = _player_ghost_scene.instance() if friendly else _ghost_scene.instance()
	ghost.action_manager = GlobalActionManager
	ghost.init(gameplay_record, Color.lightcoral if friendly else Color.lightblue)
	ghost.connect("ghost_attack", self, "_on_ghost_attack")
	return ghost




func _on_ghost_attack(attacker, trigger):
	var action = GlobalActionManager.get_action_for_trigger(trigger, attacker.ghost_index)
	GlobalActionManager.set_active(action, true, attacker, get_tree().get_root())



func _spawn_player(player_id, spawn_point, team_id):
	set_physics_process(true)
	player = _spawn_character(_player_scene, spawn_point)
	assert(player.button_overlay.connect("button_pressed", self, "_on_player_ready") == OK)
	player.spawn_point = spawn_point
	player.team_id =team_id
	player.player_id = player_id
	player.set_name(str(player_id))
	id = player_id
	
	# Apply visibility mask to all entities which have been here before the player
	for enemy in enemies.values():
		_apply_visibility_mask(enemy)
	for ghosts in _enemy_ghosts_dic.values():
		for ghost in ghosts.values():
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
	_enemy_ghosts_dic[enemy_id] = {}


func _despawn_enemy(enemy_id):
	enemies[enemy_id].queue_free()
	enemies.erase(enemy_id)
	for i in _enemy_ghosts_dic[enemy_id]:
		_enemy_ghosts_dic[enemy_id][i].queue_free()
	_enemy_ghosts_dic.erase(enemy_id)


func _spawn_character(character_scene, spawn_point):
	var character = character_scene.instance()
	character.transform.origin = spawn_point
	add_child(character)
	return character


func _update_character_positions(world_state: WorldState):
	if not _game_phase_in_progress:
		return
	if time_of_last_world_state < world_state.timestamp:
		time_of_last_world_state = world_state.timestamp
		time_since_last_server_update = 0

		var player_states: Dictionary = world_state.player_states

		# Handle own player
		if player_states.has(id):
			var server_player: PlayerState = player_states[id]

			player.handle_network_update(server_player.position, server_player.timestamp)

			player_states.erase(id)

		for enemy_id in player_states:
			if enemies.has(enemy_id):
				var enemy = enemies[enemy_id]

				# Set parameters for interpolation
				enemy.last_position = enemy.transform.origin
				enemy.last_velocity = enemy.velocity
				enemy.rotation.y = player_states[enemy_id].rotation
				enemy.server_position = player_states[enemy_id].position
				enemy.server_velocity = player_states[enemy_id].velocity
				enemy.server_acceleration = player_states[enemy_id].acceleration


func _on_player_hit(hit_player_id):
	if hit_player_id == id:
		# Own player was hit
		player.receive_hit()
	else:
		enemies[hit_player_id].receive_hit()

func _on_ghost_hit(hit_ghost_player_owner, hit_ghost_id):
	if hit_ghost_player_owner == id:
		_my_ghosts[hit_ghost_id].receive_hit()
	else:
		_enemy_ghosts_dic[hit_ghost_player_owner][hit_ghost_id].receive_hit()


func _on_player_action(player_id, action_type):
	var player = enemies[player_id]
	player.set_action_status(action_type, true)
	var action = GlobalActionManager.get_action(action_type)
	GlobalActionManager.set_active(action, true, _player, get_tree().root)

func _on_capture_point_captured(capturing_player_id, capture_point):
	level.get_capture_points()[capture_point].capture(capturing_player_id)
	
	if capturing_player_id == id:
		player.move_camera_to_overview()
		player.set_overview_light_enabled(true)
	
func _on_capture_point_team_changed(capturing_player_id, capture_point):
	level.get_capture_points()[capture_point].set_capturing_player(capturing_player_id)
	
func _on_capture_point_status_changed(capturing_player_id, capture_point, capture_progress):
	level.get_capture_points()[capture_point].set_capture_status(capturing_player_id, capture_progress)
	
func _on_capture_point_capture_lost(capturing_player_id, capture_point):
	level.get_capture_points()[capture_point].capture_lost(capturing_player_id)
	
	if capturing_player_id == id:
		player.follow_camera()
		player.set_overview_light_enabled(false)
