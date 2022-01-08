extends TutorialScenario
class_name TutorialScenario_1




func _ready():
	# Shorten prep phase
	_round_manager._preparation_phase_time = 3.0
	_player._hud.add_custom_max_time("prep_phase_time", 3.0)
	_rounds = 2
	add_round_start_function(funcref(self, "_started_round_1"))
	add_round_condition_function(funcref(self, "_check_completed_round_1"))
	add_round_end_function(funcref(self, "_completed_round_1"))
	
	add_round_start_function(funcref(self, "_started_round_2"))
	add_round_condition_function(funcref(self, "_check_completed_round_2"))
	add_round_end_function(funcref(self, "_completed_round_2"))
	


func _started_round_1():
	var first_spawn_point = _level.get_capture_points()[1]
	_player.set_custom_view_target(first_spawn_point)
	_goal_element_1.set_content("Capture!", first_spawn_point)
	_goal_element_1.show()
	_player.kb.visible = true
	_character_manager._round_manager._start_game()
	yield(_round_manager, "game_phase_started")
	add_sub_condition(funcref(self, "_move_sub_condition_start"), funcref(self, "_move_sub_condition"), funcref(self, "_move_sub_condition_end"))
	add_sub_condition(funcref(self, "_dash_sub_condition_start"), funcref(self, "_dash_sub_condition"), funcref(self, "_dash_sub_condition_end"))


func _check_completed_round_1() -> bool:
	return _level.get_capture_points()[0].get_capture_progress() == 1.0  \
			or _level.get_capture_points()[1].get_capture_progress() >= 1.0 \


func _completed_round_1() -> void:
	_bottom_element.hide()
	_goal_element_1.hide()
	_goal_element_2.hide()
	clear_sub_conditions()


func _started_round_2() -> void:	
	_character_manager._round_manager.round_index += 1
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
	# setting enemy timeline back to the first one
	_character_manager._on_timeline_picked(1,0)
	
	_player.set_custom_view_target(_level.get_capture_points()[0])
	_goal_element_1.set_content("Capture!", _level.get_capture_points()[0])
	_goal_element_1.show()
	
	_goal_element_2.set_content("Your past", _ghost_manager._player_ghosts[0].kb)
	_goal_element_2.show()
	
	yield(_round_manager, "game_phase_started")
	add_sub_condition(funcref(self, "_enemy_point_captured_condition_start"), funcref(self, "_enemy_point_captured_condition"), funcref(self, "_enemy_point_captured_condition_end"))
	add_sub_condition(funcref(self, "_enemy_killed_condition_start"), funcref(self, "_enemy_killed_condition"), funcref(self, "_enemy_killed_condition_end"))
	


func _check_completed_round_2() -> bool:
	return _level.get_capture_points()[0].get_capture_progress() == 1.0 \
			and _level.get_capture_points()[1].get_capture_progress() >= 1.0 \
			and _level.get_capture_points()[0].get_progress_team() == 0 \
			and _level.get_capture_points()[1].get_progress_team() == 0 \


func _completed_round_2() -> void:
	_bottom_element.hide()
	_goal_element_1.hide()
	_goal_element_2.hide()
	clear_sub_conditions()


func _move_sub_condition_start() -> void:
	_bottom_element.show()
	_bottom_element.set_content("Move!", TutorialUIBottomElement.Controls.Move)


func _move_sub_condition() -> bool:
	return (_player.spawn_point - _player.get_position()).length() > 5


func _move_sub_condition_end() -> void:
	_bottom_element.hide()


func _dash_sub_condition_start() -> void:
	_character_manager.toggle_trigger(ActionManager.Trigger.SPECIAL_MOVEMENT_START, true)
	_bottom_element.show()
	_bottom_element.set_content("Dash!", TutorialUIBottomElement.Controls.Dash)

func _dash_sub_condition() -> bool:
	return _player.get_dash_ammunition() != 2


func _dash_sub_condition_end() -> void:
	_bottom_element.hide()



func _enemy_point_captured_condition_start() -> void:
	_enemy.kb.visible = true
	var _error = _enemy.connect("client_hit", self, "_on_enemy_hit")
	_enemy.set_position(Vector3(0,0,-10))
	_enemyAI = EnemyAI.new(_enemy)
	_enemyAI.add_waypoint(Vector2(0, -3))
	_enemyAI.set_character_to_shoot(_player)
	_enemyAI.peaceful = true
	add_child(_enemyAI)
	_enemyAI.start()


func _enemy_point_captured_condition() -> bool:
	return _level.get_capture_points()[0].get_capture_progress() >= 1.0 \
			and _level.get_capture_points()[0].get_progress_team() == 1 


func _enemy_point_captured_condition_end() -> void:
	add_post_process_exception(_goal_element_1)
	add_post_process_exception(_bottom_element)
	_character_manager._apply_visibility_always(_enemy)
	_player.set_custom_view_target(_enemy.get_body())
	_bottom_element.show()
	_bottom_element.set_content("Oh no! The enemy captured a point!", TutorialUIBottomElement.Controls.None, true)
	_goal_element_1.set_content("Enemy", _enemy.get_body())


func _enemy_killed_condition_start() -> void:
	add_post_process_exception(_enemy)
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause()
	_character_manager._apply_visibility_mask(_enemy)
	_player.follow_camera()
	remove_post_process_exception(_goal_element_1)
	remove_post_process_exception(_bottom_element)
	remove_post_process_exception(_enemy)
	_goal_element_1.set_content("Kill!", _enemy.get_body())
	_bottom_element.set_content("Melee!",TutorialUIBottomElement.Controls.Melee)
	_character_manager.toggle_trigger(ActionManager.Trigger.DEFAULT_ATTACK_START, true)


func _enemy_killed_condition() -> bool:
	return _enemy.currently_dying


func _enemy_killed_condition_end() -> void:
	_bottom_element.hide()
	_goal_element_1.set_content("Capture!", _level.get_capture_points()[0])
	_enemyAI.stop()
	_enemy.kb.visible = false


func _on_enemy_hit(hit_data: HitData):
	_enemy.server_hit(hit_data)
