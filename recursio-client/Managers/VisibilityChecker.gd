extends Node
class_name VisibilityChecker


var _player
var _enemies := []


func set_player(new_player):
	_player = new_player


func reset():
	if _player:
		_player.set_visibility_visualization_visible(false)
	
	_player = null


func set_enemies(enemy, enemy_ghosts):
	_enemies = [enemy]
	
	for ghost in enemy_ghosts:
		if ghost.is_active():
			_enemies.append(ghost)


func _process(delta):
	if _player and not _enemies.empty():
		# Collect positions of enemies which are currently seeing the player
		var at_least_one_visible = false
		var positions = []
		
		for enemy in _enemies:
			if enemy is GhostBase and not enemy.is_playing():
				continue
			
			var player_pos = _player.kb.global_transform.origin
			var enemy_pos = enemy.kb.global_transform.origin
			var player_enemy_vector = enemy_pos - player_pos
			
			# Check if the enemy is within range and within view angle
			# The values of 1.5 and 50 were found via trial-and-error - probably can't be generalized
			# because it depends on many factors...
			if player_enemy_vector.length() < Constants.get_value("visibility", "spot_range") + 1.5 \
					and player_enemy_vector.angle_to(enemy.kb.transform.basis.z) < deg2rad(50):
				# Check whether the line of sight is occluded via a raycast
				var space_state = get_viewport().get_world().direct_space_state
				var result = space_state.intersect_ray(player_pos, enemy_pos, [_player.kb, enemy.kb])
				
				if result.empty():
					positions.append(enemy_pos)
					at_least_one_visible = true
		
		# Apply
		_player.set_visibility_visualization_enemy_positions(positions)
		
		if at_least_one_visible:
			_player.set_visibility_visualization_visible(true)
		else:
			_player.set_visibility_visualization_visible(false)
