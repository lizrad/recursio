extends TutorialScenario
class_name TutorialScenario_1




func _ready():
	# Shorten game phase
	_round_manager._game_phase_time = 20.0
	_player._hud.add_custom_max_time("game_phase_time", 20.0)
	_rounds = 2
	add_round_start_function(funcref(self, "_started_round_1"))
	add_round_condition_function(funcref(self, "_check_completed_round_1"))
	add_round_end_function(funcref(self, "_completed_round_1"))
	
	add_round_start_function(funcref(self, "_started_round_2"))
	add_round_condition_function(funcref(self, "_check_completed_round_2"))
	add_round_end_function(funcref(self, "_completed_round_2"))
	


func _started_round_1():
	_character_manager._on_timeline_picked(0,0)
	_character_manager._on_timeline_picked(1,0)
	_player.kb.visible = true
	_character_manager._round_manager._start_game(true)
	_bottom_element.set_content("Start Round", TutorialUIBottomElement.Controls.Ready)
	_bottom_element.show()
	yield(_round_manager, "countdown_phase_started")
	_bottom_element.hide()
	var first_point = _level.get_capture_points()[1]
	_player.set_custom_view_target(first_point)
	_goal_element_1.set_content("Capture!", first_point)
	_goal_element_1.show()
	
	yield(_round_manager, "game_phase_started")
	_player.follow_camera()
	add_sub_condition(funcref(self, "_move_sub_condition_start"), funcref(self, "_move_sub_condition"), funcref(self, "_move_sub_condition_end"))
	add_sub_condition(funcref(self, "_aim_sub_condition_start"), funcref(self, "_aim_sub_condition"), funcref(self, "_aim_sub_condition_end"))
	add_sub_condition(funcref(self, "_dash_sub_condition_start"), funcref(self, "_dash_sub_condition"), funcref(self, "_dash_sub_condition_end"))
	yield (_round_manager, "preparation_phase_started")
	_goal_element_1.hide()
	if captured_once:
		_switch_to_next_round()
	else:
		add_post_process_exception(_bottom_element)
		_bottom_element.show()
		_bottom_element.set_content("Oh no the timer ran out and you failed\nto capture the point once.", TutorialUIBottomElement.Controls.None, true)
		pause()
		yield(_bottom_element, "continue_pressed")
		unpause()
		var round_timer = _player.get_node("KinematicBody/HUD/Timer/TimerProgressBar")
		_goal_element_1.show()
		add_post_process_exception(_goal_element_1)
		_goal_element_1.set_content("Round Timer", round_timer)
		_bottom_element.set_content("Try the first round again and watch the timer", TutorialUIBottomElement.Controls.None, true)
		pause()
		yield(_bottom_element, "continue_pressed")
		unpause()
		_bottom_element.hide()
		_goal_element_1.hide()
		remove_post_process_exception(_goal_element_1)
		remove_post_process_exception(_bottom_element)
		clear_sub_conditions()
		_started_round_1()
	
	
var captured_once = false
func _check_completed_round_1() -> bool:
	if _level.get_capture_points()[1].get_capture_progress() >= 1.0 and not captured_once:
		captured_once = true
		_bottom_element.show()
		_bottom_element.set_content("Now wait for the round to end.")
		var round_timer = _player.get_node("KinematicBody/HUD/Timer/TimerProgressBar")
		_goal_element_1.set_content("Round Timer", round_timer)
		_goal_element_1.show()
	return false


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
	_character_manager._on_timeline_picked(0,1)
	
	add_post_process_exception(_bottom_element)
	_bottom_element.set_content("After each round the preparation phase begins.", TutorialUIBottomElement.Controls.None, true)
	_bottom_element.show()
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause()
	
	add_post_process_exception(_goal_element_1)
	add_post_process_exception(_goal_element_2)
	add_post_process_exception(_goal_element_3)
	_goal_element_1.set_content("Timeline 1", _level.get_spawn_points(0)[0])
	_goal_element_2.set_content("Timeline 2", _level.get_spawn_points(0)[1])
	_goal_element_3.set_content("Timeline 3", _level.get_spawn_points(0)[2])
	_goal_element_1.show()
	_goal_element_2.show()
	_goal_element_3.show()
	_bottom_element.set_content("In the real game you could swap between the timelines.", TutorialUIBottomElement.Controls.None, true)
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause()
	
	remove_post_process_exception(_goal_element_1)
	remove_post_process_exception(_goal_element_2)
	remove_post_process_exception(_goal_element_3)
	_goal_element_1.hide()
	_goal_element_2.hide()
	_goal_element_3.hide()
	_bottom_element.set_content("You can also see the paths you took in the other timelines.", TutorialUIBottomElement.Controls.None, true)
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause()
	
	remove_post_process_exception(_bottom_element)
	_bottom_element.hide()
	
	_goal_element_1.set_content("How you moved", _ghost_manager._player_ghosts[0].get_node("GhostPath/PathMiddle"))
	_goal_element_1.show()
	
	_bottom_element.set_content("Start Round", TutorialUIBottomElement.Controls.Ready)
	_bottom_element.show()
	
	
	yield(_round_manager, "countdown_phase_started")
	
	_bottom_element.hide()
	_player.set_custom_view_target(_level.get_capture_points()[0])
	_goal_element_1.set_content("Capture simultaneously!", _level.get_capture_points()[0])
	_goal_element_1.show()
	
	_goal_element_2.set_content("Your past", _ghost_manager._player_ghosts[0].kb)
	_goal_element_2.show()
	
	_goal_element_3.set_content("You control", _player.get_body())
	_goal_element_3.show()
	
	yield(_round_manager, "game_phase_started")
	_player.follow_camera()
	add_sub_condition(funcref(self, "_enemy_point_captured_condition_start"), funcref(self, "_enemy_point_captured_condition"), funcref(self, "_enemy_point_captured_condition_end"))
	add_sub_condition(funcref(self, "_enemy_killed_condition_start"), funcref(self, "_enemy_killed_condition"), funcref(self, "_enemy_killed_condition_end"))
	
	yield (_round_manager, "preparation_phase_started")
	_goal_element_1.hide()
	_goal_element_2.hide()
	_goal_element_3.hide()
	_bottom_element.show()
	add_post_process_exception(_bottom_element)
	_bottom_element.set_content("Oh no the timer ran out and you failed\nto capture the second point", TutorialUIBottomElement.Controls.None, true)
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause()
	var round_timer = _player.get_node("KinematicBody/HUD/Timer/TimerProgressBar")
	_goal_element_1.show()
	add_post_process_exception(_goal_element_1)
	_goal_element_1.set_content("Round Timer", round_timer)
	_bottom_element.set_content("Try the second round again and watch the timer", TutorialUIBottomElement.Controls.None, true)
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause()
	_bottom_element.hide()
	_goal_element_1.hide()
	remove_post_process_exception(_goal_element_1)
	remove_post_process_exception(_bottom_element)
	clear_sub_conditions()
	_started_round_2()


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


var _start_rotation: float

func _aim_sub_condition_start() -> void:
	_start_rotation = _player.get_rotation_y()
	_bottom_element.show()
	_bottom_element.set_content("Aim!", TutorialUIBottomElement.Controls.Look)


func _aim_sub_condition() -> bool:
	var diff =  _player.get_rotation_y() - _start_rotation
	# deals with rotation where we jump over the full circle and keeps degrees between -180 and 180
	diff = (diff + PI)
	diff = diff - floor(diff/(2*PI)) * (2*PI)
	diff -= PI
	# rotate at least 90 degrees
	return abs(diff) > PI*0.5


func _aim_sub_condition_end() -> void:
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
	_goal_element_1.set_content("Capture simultaneously!", _level.get_capture_points()[0])
	_enemyAI.stop()
	_enemy.kb.visible = false


func _on_enemy_hit(hit_data: HitData):
	_enemy.server_hit(hit_data)
