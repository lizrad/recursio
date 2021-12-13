extends Node


var _player
var _enemies


func _process(delta):
	_player = get_parent()._player
	_enemies = [get_parent()._enemy]
	
	_enemies.append_array(get_parent().get_node("GhostManager")._enemy_ghosts)
	
	if _player and _enemies[0]:
		_player.set_visibility_visualization_visible(false)
		
		for enemy in _enemies:
			var player_pos = _player.kb.global_transform.origin
			var enemy_pos = enemy.kb.global_transform.origin
			
			if (enemy_pos - player_pos).length() < Constants.get_value("visibility", "spot_range"):
				var space_state = get_viewport().get_world().direct_space_state
				var result = space_state.intersect_ray(player_pos, enemy_pos, [_player.kb, enemy.kb])
				
				if not result.empty():
					_player.set_visibility_visualization_visible(true)
					_player.set_visibility_visualization_enemy_position(enemy_pos)
