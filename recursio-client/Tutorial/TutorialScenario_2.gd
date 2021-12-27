extends TutorialScenario
class_name TutorialScenario_2

var _player: Player
var _enemy: Enemy
var _enemyAI: EnemyAI

func _ready():
	_rounds = 3
	_completion_delay = 2.0
	add_round_start_function(funcref(self, "_started_round_1"))
	add_round_condition_function(funcref(self, "_check_completed_round_1"))
	add_round_end_function(funcref(self, "_completed_round_1"))
	
	add_round_start_function(funcref(self, "_started_round_2"))
	add_round_condition_function(funcref(self, "_check_completed_round_2"))
	add_round_end_function(funcref(self, "_completed_round_2"))
	
	add_round_start_function(funcref(self, "_started_round_3"))
	add_round_condition_function(funcref(self, "_check_completed_round_3"))
	add_round_end_function(funcref(self, "_completed_round_3"))	
	
	
	_character_manager._on_spawn_player(0, Vector3.ZERO, 0)
	_player = _character_manager.get_player()
	
	_player.kb.visible = false
	_player.block_switching = true
	_character_manager.hide_player_button_overlay = true
	# Shorten prep phase
	_round_manager._preparation_phase_time = 3.0
	
	var spawn_point = _game_manager.get_spawn_point(1, 0).global_transform.origin
	_character_manager._on_spawn_enemy(1, spawn_point, 1)
	_enemy = _character_manager.get_enemy()
	
	_character_manager.enemy_is_server_driven = false
	_enemy.kb.visible = false
	_goal_element_1.init(_player.get_camera())
	_goal_element_2.init(_player.get_camera())


func _started_round_1():
	_bottom_element.show()
	_bottom_element.set_content("Welcome to the second tutorial!")
	_player.kb.visible = true
	_player.block_movement = true
	_player.block_input = true
	_enemy.kb.visible = true
	_enemy.block_movement = false
	
	var _error = _player.connect("client_hit", self, "_on_player_hit")
	_error = _enemy.connect("client_hit", self, "_on_enemy_hit")
	
	_enemyAI = EnemyAI.new(_enemy)
	_enemyAI.add_waypoint(Vector2(-12, 8))
	_enemyAI.add_waypoint(Vector2(-5, 5))
	
	_enemyAI.set_character_to_shoot(_player)
	
	add_child(_enemyAI)
	_enemyAI.start()
	
	_character_manager._round_manager._start_game()
	_player.block_movement = true
	yield(_round_manager, "game_phase_started")
	_player.block_movement = true
	
	_bottom_element.set_content("Capture this point!")
	_goal_element_1.show()
	_goal_element_1.set_content("Capture!", _level.get_capture_points()[1])
	_player.block_movement = false
	yield(get_tree().create_timer(2), "timeout")
	
	# Wait until player gets hit
	yield(_player, "client_hit")
	_player.block_input = false
	
	_bottom_element.set_content("You got hit!")
	yield(get_tree().create_timer(2), "timeout")
	
	_goal_element_1.set_content("Kill!", _enemy.get_body())
	_bottom_element.set_content("Kill the enemy before they can kill you!")
	yield(get_tree().create_timer(2), "timeout")
	
	_bottom_element.set_content("Fire!", TutorialUIBottomElement.Controls.Fire)
	
	yield(_enemy, "client_hit")
	_bottom_element.set_content("Now capture the point.")
	_goal_element_1.set_content("Capture!", _level.get_capture_points()[1])


func _check_completed_round_1() -> bool:
	return _level.get_capture_points()[1].capture_progress == 1.0


func _completed_round_1() -> void:
	_enemyAI.stop()


func _started_round_2() -> void:
	_goal_element_1.hide()
	
	_bottom_element.set_content("Good job!")
	yield(get_tree().create_timer(2), "timeout")
	
	_character_manager._round_manager.round_index += 1
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
	_enemy.kb.visible = false
	_player.kb.visible = false
	_player.block_movement = true
	
	for ghost in _ghost_manager._ghosts:
		var _error = ghost.connect("client_hit", self, "_on_ghost_hit", [ghost])
	
	_bottom_element.set_content("Now watch what happens with your ghost.")
	
	yield(get_tree().create_timer(_character_manager._round_manager._preparation_phase_time + 0.1), "timeout")
	_player.move_camera_to_overview()
	
	yield(get_tree().create_timer(3), "timeout")
	_goal_element_1.show()
	_goal_element_1.set_content("Repeats!", _ghost_manager._player_ghosts[0].get_body())
	yield(_ghost_manager._player_ghosts[0], "client_hit")
	_goal_element_1.set_content("Dead!", _ghost_manager._player_ghosts[0].get_body())


func _check_completed_round_2() -> bool:
	return _ghost_manager._player_ghosts[0].currently_dying


func _completed_round_2() -> void:
	_goal_element_1.hide()
	_bottom_element.set_content("Killing your past timeline stops it completely.")
	

func _started_round_3() -> void:
	_ghost_manager._player_ghosts[0].disconnect("client_hit", self, "_on_ghost_hit")
	var _error = _ghost_manager._player_ghosts[0].connect("client_hit", self, "_on_ghost_hit_soft_lock", [_ghost_manager._player_ghosts[0]])
	yield(get_tree().create_timer(4), "timeout")
	
	_bottom_element.set_content("Prevent your past death!")
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
	_player.kb.visible = true
	_enemy.kb.visible = true
	yield(_round_manager, "game_phase_started")
	
	_bottom_element.set_content("Fire!", TutorialUIBottomElement.Controls.Fire)
	_goal_element_1.show()
	_goal_element_1.set_content("Place Wall!",_ghost_manager._enemy_ghosts[0].get_body())
	yield(_ghost_manager._enemy_ghosts[0], "client_hit")
	
	_bottom_element.set_content("Now get the other point!")
	_goal_element_1.set_content("Capture!",_level.get_capture_points()[0])
	


func _check_completed_round_3() -> bool:
	return _level.get_capture_points()[1].capture_progress == 1.0 \
			and _level.get_capture_points()[0].capture_progress == 1.0 \


func _completed_round_3() -> void:
	_bottom_element.set_content("Good job!")


func _on_player_hit(perpetrator):
	_player.server_hit(perpetrator)


func _on_enemy_hit(perpetrator):
	_enemy.server_hit(perpetrator)


func _on_ghost_hit(perpetrator, ghost):
	if ghost is PlayerGhost:
		ghost.toggle_visibility_light(false)
	ghost.server_hit(perpetrator)


func _on_ghost_hit_soft_lock(perpetrator, ghost: PlayerGhost):	
	ghost.toggle_visibility_light(false)
	ghost.server_hit(perpetrator)
	_bottom_element.set_content("Oh no, your ghost died! Try again.")
	yield(get_tree().create_timer(2), "timeout")
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
	
	if perpetrator is Player:
		_bottom_element.set_content("Melee!", TutorialUIBottomElement.Controls.Melee)
		yield(get_tree().create_timer(2), "timeout")
