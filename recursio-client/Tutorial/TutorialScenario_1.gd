extends TutorialScenario
class_name TutorialScenario_1


var _player: Player
var _enemy: Enemy
var _enemyAI: EnemyAI


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
	
	_character_manager.hide_player_button_overlay = true

	# Shorten prep phase
	_round_manager._preparation_phase_time = 3.0
	
	var spawn_point = _game_manager.get_spawn_point(1, 0).global_transform.origin
	_character_manager._on_spawn_enemy(1, spawn_point, 1)
	_character_manager.enemy_is_server_driven = false
	_character_manager.get_enemy().kb.visible = false
	
	_enemy = _character_manager.get_enemy()
	_player = _character_manager.get_player()
	
	_player.kb.visible = false
	_goal_element_1.init(_player.get_camera())
	_goal_element_2.init(_player.get_camera())


func _started_round_1():
	
	_bottom_element.show()
	_bottom_element.set_content("Welcome to the first tutorial!")
	
	yield(get_tree().create_timer(2), "timeout")
	
	_bottom_element.set_content("Capture both points to win!")
	_goal_element_1.set_goal(_level.get_capture_points()[1])
	_goal_element_1.set_text("")
	_goal_element_1.show()
	_goal_element_2.set_goal(_level.get_capture_points()[0])
	_goal_element_2.set_text("")
	_goal_element_2.show()
	yield(get_tree().create_timer(2), "timeout")
	
	_goal_element_2.hide()
	_bottom_element.set_content("Start with this one!")
	_player.set_custom_view_target(_level.get_capture_points()[1])
	_goal_element_1.set_text("Capture!")
	_goal_element_1.show()
	
	yield(get_tree().create_timer(2), "timeout")
	
	_player.follow_camera()
	
	
	_player.kb.visible = true
	_character_manager._round_manager._start_game()
	yield(get_tree().create_timer(6), "timeout")
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
	
	
	
	_bottom_element.set_content("Now get the other one.")
	_bottom_element.show()
	
	_player.set_custom_view_target(_level.get_capture_points()[0])
	_goal_element_1.set_goal(_level.get_capture_points()[0])
	_goal_element_1.set_text("Capture!")
	_goal_element_1.show()
	
	yield(get_tree().create_timer(2), "timeout")
	
	_goal_element_2.set_goal(_ghost_manager._player_ghosts[0].kb)
	_goal_element_2.set_text("Your past")
	_goal_element_2.show()
	
	yield(get_tree().create_timer(2), "timeout")
	_player.follow_camera()
	add_sub_condition(funcref(self, "_enemy_point_captured_condition_start"), funcref(self, "_enemy_point_captured_condition"), funcref(self, "_enemy_point_captured_condition_end"))
	add_sub_condition(funcref(self, "_enemy_killed_condition_start"), funcref(self, "_enemy_killed_condition"), funcref(self, "_enemy_killed_condition_end"))
	


func _check_completed_round_2() -> bool:
	return _level.get_capture_points()[0].get_capture_progress() == 1.0 \
			and _level.get_capture_points()[1].get_capture_progress() >= 1.0 \
			and _level.get_capture_points()[0].get_progress_team() == 0 \
			and _level.get_capture_points()[1].get_progress_team() == 0 \

func _completed_round_2() -> void:
	_bottom_element.set_content("Good job!")


func _move_sub_condition_start() -> void:
	_bottom_element.show()
	_bottom_element.set_content("Move!", TutorialUIBottomElement.Controls.Move)
func _move_sub_condition() -> bool:
	return (_player.spawn_point - _player.get_position()).length() > 5
func _move_sub_condition_end() -> void:
	_bottom_element.hide()


func _dash_sub_condition_start() -> void:
	_bottom_element.show()
	_bottom_element.set_content("Dash!", TutorialUIBottomElement.Controls.Dash)
func _dash_sub_condition() -> bool:
	return _player.get_dash_ammunition() != 2
func _dash_sub_condition_end() -> void:
	_bottom_element.hide()



func _enemy_point_captured_condition_start() -> void:
	_enemy.kb.visible = true
	var _error = _enemy.connect("client_hit", self, "_on_enemy_hit")
	_enemy.set_position(Vector3(0,0,-12))
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
	_bottom_element.set_content("The enemy captured a point!")
	_goal_element_1.set_goal(_enemy.get_body())
	_goal_element_1.set_text("Enemy")
	_player.set_custom_view_target(_enemy.get_body())

func _enemy_killed_condition_start() -> void:
	yield(get_tree().create_timer(2), "timeout")
	_goal_element_1.set_goal(_enemy.get_body())
	_goal_element_1.set_text("Kill!")
	_player.follow_camera()
	_bottom_element.set_content("Melee!",TutorialUIBottomElement.Controls.Melee)
func _enemy_killed_condition() -> bool:
	return _enemy.currently_dying
func _enemy_killed_condition_end() -> void:
	_bottom_element.set_content("Capture the point!")
	_goal_element_1.set_goal(_level.get_capture_points()[0])
	_goal_element_1.set_text("Capture!")
	_enemyAI.stop()
	_enemy.kb.visible = false

func _on_enemy_hit(perpetrator):
	_enemy.server_hit(perpetrator)
