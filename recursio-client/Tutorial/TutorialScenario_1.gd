extends TutorialScenario
class_name TutorialScenario_1


func _ready():
	_rounds = 2
	_completion_delay = 2.0
	add_round_start_function(funcref(self, "_started_round_1"))
	add_round_condition_function(funcref(self, "_check_completed_round_1"))
	add_round_end_function(funcref(self, "_completed_round_1"))
	
	add_round_start_function(funcref(self, "_started_round_2"))
	add_round_condition_function(funcref(self, "_check_completed_round_2"))
	add_round_end_function(funcref(self, "_completed_round_2"))
	
	_character_manager._on_spawn_player(0, Vector3.ZERO, 0)
	_character_manager.get_player().kb.visible = false
	_character_manager.hide_player_button_overlay = true
	_goal_element_1.init(_character_manager.get_player().get_camera())
	_goal_element_2.init(_character_manager.get_player().get_camera())

	# Shorten prep phase
	_round_manager._preparation_phase_time = 3.0
	
	var spawn_point = _game_manager.get_spawn_point(1, 0).global_transform.origin
	_character_manager._on_spawn_enemy(1, spawn_point, 1)
	_character_manager.enemy_is_server_driven = false
	_character_manager.get_enemy().kb.visible = false


func _started_round_1():
	_toggle_ui(true)
	_bottom_element.set_text("Welcome to the first tutorial!")
	_bottom_element.set_control(TutorialUIBottomElement.Controls.None)
	_bottom_element.show()
	
	yield(get_tree().create_timer(2), "timeout")
	
	_bottom_element.set_text("Capture both points to win!")
	_goal_element_1.set_goal(_level.get_capture_points()[1])
	_goal_element_1.set_text("")
	_goal_element_1.show()
	_goal_element_2.set_goal(_level.get_capture_points()[0])
	_goal_element_2.set_text("")
	_goal_element_2.show()
	yield(get_tree().create_timer(2), "timeout")
	
	_goal_element_2.hide()
	_bottom_element.set_text("Start with this one!")
	_character_manager.get_player().set_custom_view_target(_level.get_capture_points()[1])
	_goal_element_1.set_text("Capture!")
	_goal_element_1.show()
	
	yield(get_tree().create_timer(2), "timeout")
	
	_character_manager.get_player().follow_camera()
	
	
	_character_manager.get_player().kb.visible = true
	_character_manager._round_manager._start_game()
	yield(get_tree().create_timer(6), "timeout")
	add_sub_condition(funcref(self, "_move_sub_condition_start"), funcref(self, "_move_sub_condition"), funcref(self, "_move_sub_condition_end"))
	add_sub_condition(funcref(self, "_dash_sub_condition_start"), funcref(self, "_dash_sub_condition"), funcref(self, "_dash_sub_condition_end"))


func _check_completed_round_1() -> bool:
	return _level.get_capture_points()[1]._capture_progress >= 0.9


func _completed_round_1() -> void:
	_bottom_element.hide()
	_goal_element_1.hide()
	_goal_element_2.hide()
	_level.get_capture_points()[1]._capture_progress = 1.0


func _started_round_2() -> void:	
	yield(get_tree().create_timer(2), "timeout")
	
	_character_manager._round_manager.round_index += 1
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
	print(_round_manager.round_index)
	_bottom_element.set_text("Now get the other one.")
	_bottom_element.set_control(TutorialUIBottomElement.Controls.None)
	_bottom_element.show()
	
	_character_manager.get_player().set_custom_view_target(_level.get_capture_points()[0])
	_goal_element_1.set_goal(_level.get_capture_points()[0])
	_goal_element_1.set_text("Capture!")
	_goal_element_1.show()
	
	yield(get_tree().create_timer(2), "timeout")
	
	_goal_element_2.set_goal(_ghost_manager._player_ghosts[0].kb)
	_goal_element_2.set_text("Your past")
	_goal_element_2.show()
	
	yield(get_tree().create_timer(2), "timeout")
	
	_bottom_element.set_text("Move!")
	_bottom_element.set_control(TutorialUIBottomElement.Controls.Move)
	_character_manager.get_player().follow_camera()


func _check_completed_round_2() -> bool:
	return _level.get_capture_points()[1]._capture_progress >= 0.9 \
			and _level.get_capture_points()[0]._capture_progress >= 0.9 \

func _completed_round_2() -> void:
	_level.get_capture_points()[0]._capture_progress = 1.0
	_level.get_capture_points()[1]._capture_progress = 1.0
	
	_toggle_ui(true)
	_tutorial_text.typing_text = "Good job!"


func _move_sub_condition_start() -> void:
	_bottom_element.show()
	_bottom_element.set_text("Move!")
	_bottom_element.set_control(TutorialUIBottomElement.Controls.Move)
func _move_sub_condition() -> bool:
	return (_character_manager.get_player().spawn_point - _character_manager.get_player().get_position()).length() > 5
func _move_sub_condition_end() -> void:
	_bottom_element.hide()
func _dash_sub_condition_start() -> void:
	_bottom_element.show()
	_bottom_element.set_text("Dash!")
	_bottom_element.set_control(TutorialUIBottomElement.Controls.Dash)
func _dash_sub_condition() -> bool:
	return _character_manager.get_player().get_dash_ammunition() != 2
func _dash_sub_condition_end() -> void:
	_bottom_element.hide()
