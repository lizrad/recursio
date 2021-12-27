extends TutorialScenario
class_name TutorialScenario_2

func _ready():
	# Shorten prep phase
	_round_manager._preparation_phase_time = 3.0
	_player._hud.add_custom_max_time("prep_phase_time", 3.0)
	_rounds = 3
	add_round_start_function(funcref(self, "_started_round_1"))
	add_round_condition_function(funcref(self, "_check_completed_round_1"))
	add_round_end_function(funcref(self, "_completed_round_1"))
	
	add_round_start_function(funcref(self, "_started_round_2"))
	add_round_condition_function(funcref(self, "_check_completed_round_2"))
	add_round_end_function(funcref(self, "_completed_round_2"))
	
	add_round_start_function(funcref(self, "_started_round_3"))
	add_round_condition_function(funcref(self, "_check_completed_round_3"))
	add_round_end_function(funcref(self, "_completed_round_3"))	


func _started_round_1():
	_bottom_element.show()
	_bottom_element.set_content("Welcome to the second tutorial!", TutorialUIBottomElement.Controls.None, true)
	_player.block_movement = true
	_player.block_input = true
	_enemy.block_movement = false
	
	var _error = _player.connect("client_hit", self, "_on_player_hit")
	_error = _enemy.connect("client_hit", self, "_on_enemy_hit")
	
	_enemyAI = EnemyAI.new(_enemy)
	_enemyAI.add_waypoint(Vector2(-5, 5))
	
	_enemyAI.set_character_to_shoot(_player)
	
	add_child(_enemyAI)
	_enemyAI.start()
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause(false)
	_character_manager._round_manager._start_game()
	
	_player.kb.visible = true
	_enemy.kb.visible = true
	_bottom_element.set_content("Capture this point!")
	_goal_element_1.show()
	_goal_element_1.set_content("Capture!", _level.get_capture_points()[1])
	
	_enemy.set_position(Vector3(-12,0, 8))
	# Wait until player gets hit
	yield(_player, "client_hit")
	
	_bottom_element.set_content("You got hit!", TutorialUIBottomElement.Controls.None, true)
	
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause(false)
	_goal_element_1.set_content("Kill!", _enemy.get_body())
	_bottom_element.set_content("Kill the enemy before they can kill you!", TutorialUIBottomElement.Controls.None, true)
	
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause(true)
	
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
	
	_bottom_element.set_content("Good job!", TutorialUIBottomElement.Controls.None, true)
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause(false)
	
	_character_manager._round_manager.round_index += 1
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
	_enemy.kb.visible = false
	_player.kb.visible = false
	_player.block_movement = true
	
	for ghost in _ghost_manager._ghosts:
		var _error = ghost.connect("client_hit", self, "_on_ghost_hit", [ghost])
	
	_bottom_element.set_content("Now watch what happens with your ghost.")
	
	yield(_round_manager, "game_phase_started")
	_player.move_camera_to_overview()
	_goal_element_1.show()
	_goal_element_1.set_content("Repeats", _ghost_manager._player_ghosts[0].get_body())


func _check_completed_round_2() -> bool:
	return _ghost_manager._player_ghosts[0].currently_dying


func _completed_round_2() -> void:
	_goal_element_1.show()
	_goal_element_1.set_content("Stays dead", _ghost_manager._player_ghosts[0].get_body())
	_bottom_element.set_content("Killing your past timeline stops it completely.", TutorialUIBottomElement.Controls.None, true)
	

func _started_round_3() -> void:
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause(true)
	_ghost_manager._player_ghosts[0].disconnect("client_hit", self, "_on_ghost_hit")
	var _error = _ghost_manager._player_ghosts[0].connect("client_hit", self, "_on_ghost_hit_soft_lock", [_ghost_manager._player_ghosts[0]])
	
	
	_goal_element_1.hide()
	_bottom_element.set_content("Prevent your past death!")
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
	_player.kb.visible = true
	_enemy.kb.visible = true
	yield(_round_manager, "game_phase_started")
	
	_bottom_element.set_content("Fire!", TutorialUIBottomElement.Controls.Fire)
	_goal_element_1.show()
	_goal_element_1.set_content("Place Wall",_ghost_manager._enemy_ghosts[0].get_body())
	yield(_level.get_capture_points()[1], "captured")
	
	_bottom_element.set_content("Now get the other point!")
	_goal_element_1.set_content("Capture",_level.get_capture_points()[0])
	


func _check_completed_round_3() -> bool:
	return _level.get_capture_points()[1].capture_progress == 1.0 \
			and _level.get_capture_points()[0].capture_progress == 1.0 \


func _completed_round_3() -> void:
	pass


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
	
	if perpetrator is Player:
		_bottom_element.set_content("Oh no, you killed your ghost! Try using a melee attack.", TutorialUIBottomElement.Controls.None, true)
	else:
		_bottom_element.set_content("Oh no, your ghost died! Try again.", TutorialUIBottomElement.Controls.None, true)
	_goal_element_1.hide()
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause(true)
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
	_goal_element_1.show()
	if perpetrator is Player:
		_bottom_element.set_content("Melee!", TutorialUIBottomElement.Controls.Melee)
		_goal_element_1.set_content("Kill", _ghost_manager._enemy_ghosts[0].get_body())
