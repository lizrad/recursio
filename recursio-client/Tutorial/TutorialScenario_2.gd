extends TutorialScenario
class_name TutorialScenario_2


var _player_killed_once : bool = false
var _enemy_killed_once : bool = false
var _captured_once : bool = false
var _soft_locked = false

func _ready():
	_round_manager._game_phase_time = 25.0
	_player._hud.add_custom_max_time("game_phase_time", 25.0)
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
	_character_manager._on_timeline_picked(0,0)
	_character_manager._on_timeline_picked(1,0)
	var _error = _player.connect("client_hit", self, "_on_player_hit")
	_error = _enemy.connect("client_hit", self, "_on_enemy_hit")
	_enemyAI = EnemyAI.new(_enemy)
	_enemyAI.add_waypoint(Vector2(-5, 5))
	_enemyAI.set_character_to_shoot(_player)
	add_child(_enemyAI)
	

	_player.kb.visible = true
	_enemy.kb.visible = true
	_character_manager._round_manager._start_game(true)
	_bottom_element.set_content("Start Round", TutorialUIBottomElement.Controls.Ready)
	_bottom_element.show()
	
	_character_manager.toggle_trigger(ActionManager.Trigger.DEFAULT_ATTACK_START, false)
	_character_manager.toggle_trigger(ActionManager.Trigger.FIRE_START, false)
	_character_manager.toggle_trigger(ActionManager.Trigger.SPECIAL_MOVEMENT_START, false)
	_character_manager.toggle_swapping(false)
	yield(_round_manager, "countdown_phase_started")
	_bottom_element.hide()
	_goal_element_1.set_content("Capture!", _level.get_capture_points()[1])
	_goal_element_1.show()
	_player.set_custom_view_target(_level.get_capture_points()[1])
	yield(_round_manager, "game_phase_started")
	_player.follow_camera()
	
	_error = _round_manager.connect("preparation_phase_started",self,"_on_prep_phase_started_round_1")
	_enemy.set_position(Vector3(-12,0, 8))
	_enemyAI.start()
	_character_manager.toggle_movement(false)
	
	# Wait so we have a chance to prevent the death later
	_bottom_element.show()
	_bottom_element.set_content("Wait 3s")
	yield(get_tree().create_timer(1), "timeout")
	_bottom_element.set_content("Wait 2s")
	yield(get_tree().create_timer(1), "timeout")
	_bottom_element.set_content("Wait 1s")
	yield(get_tree().create_timer(1), "timeout")
	_bottom_element.set_content("Wait 0s")
	_bottom_element.hide()
	
	_character_manager.toggle_trigger(ActionManager.Trigger.SPECIAL_MOVEMENT_START, true)
	_character_manager.toggle_movement(true)
	
	# Wait until player gets hit
	yield(_player, "client_hit")
	_player_killed_once = true
	_goal_element_1.set_content("Kill!", _enemy.get_body())
	_character_manager.toggle_trigger(ActionManager.Trigger.DEFAULT_ATTACK_START, true)
	_character_manager.toggle_trigger(ActionManager.Trigger.FIRE_START, true)
	_bottom_element.show()
	_bottom_element.set_content("Shoot!", TutorialUIBottomElement.Controls.Shoot)
	
	# Wait until the enemy is killed
	yield(_enemy, "client_hit")
	_enemy_killed_once = true
	_bottom_element.hide()
	_goal_element_1.set_content("Capture!", _level.get_capture_points()[1])




func _check_completed_round_1() -> bool:
	if _level.get_capture_points()[1].get_capture_progress() >= 1.0 and _player_killed_once and _enemy_killed_once and not _captured_once:
		_captured_once = true
		_bottom_element.show()
		_bottom_element.set_content("Now wait for the round to end.")
		var round_timer = _player.get_node("KinematicBody/HUD/Timer/TimerProgressBar")
		_goal_element_1.set_content("Round Timer", round_timer)
		_goal_element_1.show()
	return false

func _on_prep_phase_started_round_1():
	_round_manager.disconnect("preparation_phase_started",self,"_on_prep_phase_started_round_1")
	_goal_element_1.hide()
	_character_manager._on_timeline_picked(0,0)
	_character_manager._on_timeline_picked(1,0)
	if _captured_once:
		_character_manager.toggle_trigger(ActionManager.Trigger.DEFAULT_ATTACK_START, false)
		_character_manager.toggle_trigger(ActionManager.Trigger.FIRE_START, false)
		_character_manager.toggle_trigger(ActionManager.Trigger.SPECIAL_MOVEMENT_START, false)
		_switch_to_next_round()
	else:
		_player.disconnect("client_hit", self, "_on_player_hit")
		_enemy.disconnect("client_hit", self, "_on_enemy_hit")
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

func _completed_round_1() -> void:
	_enemyAI.stop()
	_enemyAI.queue_free()
	_enemyAI = null
	_auto_skip_next_prep = true


func _started_round_2() -> void:
	_goal_element_1.hide()
	_character_manager._round_manager.round_index = 1
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
	_level.get_spawn_point_node(0,1).set_active(false)
	_enemy.kb.visible = false
	_player.kb.visible = false
	
	for ghost in _ghost_manager._ghosts:
		var _error = ghost.connect("client_hit", self, "_on_ghost_hit", [ghost])
	
	_bottom_element.show()
	_bottom_element.set_content("Watch what would happen with your previous timeline.")
	_character_manager.toggle_swapping(false)
	yield(_round_manager, "game_phase_started")
	_character_manager.toggle_player_input_pause(true)
	_goal_element_1.show()
	_goal_element_1.set_content("Repeats", _ghost_manager._player_ghosts[0].get_body())
	# Wait until the ghost starts movings
	yield(get_tree().create_timer(3), "timeout")
	_player.move_camera_to_overview()


func _check_completed_round_2() -> bool:
	return _ghost_manager._player_ghosts[0].currently_dying


func _completed_round_2() -> void:
	add_post_process_exception(_ghost_manager._player_ghosts[0].get_body())
	add_post_process_exception(_bottom_element)
	add_post_process_exception(_goal_element_1)
	_goal_element_1.show()
	_goal_element_1.set_content("Stays dead", _ghost_manager._player_ghosts[0].get_body())
	_bottom_element.show()
	_bottom_element.set_content("Killing your past timeline stops it completely.\nEverything that was recorded in the past round is lost.", TutorialUIBottomElement.Controls.None, true)
	
	

func _started_round_3() -> void:
	# Deal with ending text of last round
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause()
	_bottom_element.set_content("You might want to prevent that.", TutorialUIBottomElement.Controls.None, true)
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause()
	remove_post_process_exception(_ghost_manager._player_ghosts[0].get_body())
	remove_post_process_exception(_bottom_element)
	remove_post_process_exception(_goal_element_1)
	_goal_element_1.hide()
	_bottom_element.hide()
	_started_round_3_without_transition()


func _started_round_3_without_transition():
	
	_character_manager.toggle_trigger(ActionManager.Trigger.DEFAULT_ATTACK_START, true)
	_character_manager.toggle_trigger(ActionManager.Trigger.FIRE_START, true)
	_character_manager.toggle_trigger(ActionManager.Trigger.SPECIAL_MOVEMENT_START, true)
	
	_ghost_manager._player_ghosts[0].disconnect("client_hit", self, "_on_ghost_hit")
	var _error = _ghost_manager._player_ghosts[0].connect("client_hit", self, "_on_ghost_hit_soft_lock", [_ghost_manager._player_ghosts[0]])
	
	_character_manager.toggle_player_input_pause(false)
	_character_manager.toggle_trigger(ActionManager.Trigger.FIRE_START, true)
	_character_manager.toggle_trigger(ActionManager.Trigger.DEFAULT_ATTACK_START, true)
	_character_manager.toggle_trigger(ActionManager.Trigger.SPECIAL_MOVEMENT_START, true)
	
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
	_character_manager._on_timeline_picked(0,1)
	_character_manager._on_timeline_picked(1,1)
	_level.get_spawn_point_node(0,1).set_active(true)
	_player.kb.visible = true
	_enemy.kb.visible = false
	_bottom_element.set_content("Start Round", TutorialUIBottomElement.Controls.Ready)
	_bottom_element.show()
	_character_manager.toggle_swapping(false)
	yield(_round_manager, "countdown_phase_started")
	_bottom_element.hide()
	yield(_round_manager, "game_phase_started")
	
	_enemy.set_position(Vector3(1200,0, 8))
	_error = _round_manager.connect("preparation_phase_started",self,"_on_prep_phase_started_round_3")
	_bottom_element.show()
	_bottom_element.set_content("Spawn Wall!", TutorialUIBottomElement.Controls.Shoot)
	_goal_element_1.show()
	_goal_element_1.set_content("Place here",_ghost_manager._enemy_ghosts[0].get_body())
	_goal_element_2.show()
	_goal_element_2.set_content("Repeats", _ghost_manager._player_ghosts[0].get_body())
	
	# Wait until the player ghost gets respawned
	yield(_ghost_manager._player_ghosts[0], "respawned")
	# wait if we really aren't soft locked
	yield(get_tree(),"idle_frame")
	if not _soft_locked:
		_round_3_end_sequence()
	

func _round_3_end_sequence():
	_player.set_custom_view_target(_ghost_manager._player_ghosts[0].get_body())
	add_post_process_exception(_bottom_element)
	add_post_process_exception(_goal_element_1)
	add_post_process_exception(_ghost_manager._player_ghosts[0])
	_goal_element_1.set_content("Respawned", _ghost_manager._player_ghosts[0].get_body())
	_bottom_element.show()
	_bottom_element.set_content("If the previous timeline does not get hit, it repeats\neverything that was recorded within the round timer.\nEven dying and respawning!", TutorialUIBottomElement.Controls.None, true)
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause()
	remove_post_process_exception(_goal_element_1)
	remove_post_process_exception(_ghost_manager._player_ghosts[0])
	_bottom_element.hide()
	
	_goal_element_1.set_content("Repeats further", _ghost_manager._player_ghosts[0].get_body())
	_player.follow_camera()
	yield(_level.get_capture_points()[1], "captured")
	_goal_element_2.show()
	_goal_element_2.set_content("Capture",_level.get_capture_points()[0])
	_player.set_custom_view_target(_level.get_capture_points()[0])
	# wait and show the point a bit before we go back to the player
	yield(get_tree().create_timer(2), "timeout")
	_player.follow_camera()

func _check_completed_round_3() -> bool:
	return _level.get_capture_points()[1].capture_progress == 1.0 \
			and _level.get_capture_points()[0].capture_progress == 1.0 \

func _on_prep_phase_started_round_3():
	_round_manager.disconnect("preparation_phase_started",self,"_on_prep_phase_started_round_3")
	_goal_element_1.hide()
	_character_manager._on_timeline_picked(0,1)
	_character_manager._on_timeline_picked(1,1)
	_ghost_manager._player_ghosts[0].connect("client_hit", self, "_on_ghost_hit")
	var _error = _ghost_manager._player_ghosts[0].disconnect("client_hit", self, "_on_ghost_hit_soft_lock")
	add_post_process_exception(_bottom_element)
	_bottom_element.show()
	_bottom_element.set_content("Oh no the timer ran out before you\ncaptured both points.", TutorialUIBottomElement.Controls.None, true)
	var round_timer = _player.get_node("KinematicBody/HUD/Timer/TimerProgressBar")
	add_post_process_exception(_goal_element_1)
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause()
	_goal_element_1.show()
	_goal_element_1.set_content("Round Timer", round_timer)
	_bottom_element.set_content("Try the round again and watch the timer", TutorialUIBottomElement.Controls.None, true)
	clear_sub_conditions()
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause()
	_bottom_element.hide()
	_goal_element_1.hide()
	remove_post_process_exception(_bottom_element)
	remove_post_process_exception(_goal_element_1)
	_started_round_3_without_transition()



func _completed_round_3() -> void:
	_goal_element_1.hide()
	_goal_element_2.hide()
	_bottom_element.hide()


func _on_player_hit(hit_data: HitData):
	_player.server_hit(hit_data)


func _on_enemy_hit(hit_data: HitData):
	_enemy.server_hit(hit_data)


func _on_ghost_hit(hit_data: HitData, ghost):
	if ghost is PlayerGhost:
		ghost.toggle_visibility_light(false)
	ghost.server_hit(hit_data)


func _on_ghost_hit_soft_lock(hit_data: HitData, ghost: PlayerGhost):	
	_soft_locked = true
	
	ghost.toggle_visibility_light(false)
	ghost.server_hit(hit_data)
	
	add_post_process_exception(_bottom_element)
	_bottom_element.show()
	if hit_data.perpetrator_team_id == _player.team_id:
		if hit_data.type == HitData.HitType.WALL:
			_bottom_element.set_content("Oh no, you killed your past with a wall.\nAny previous timelines die on contact with them.\nMaybe use a melee attack instead.", TutorialUIBottomElement.Controls.None, true)
		else:
			_bottom_element.set_content("Do not to hit your own past.\nYou need it to capture the first capture point.", TutorialUIBottomElement.Controls.None, true)
	else:
		_bottom_element.set_content("Oh no, you did not prevent the death of\nyour previous timeline!", TutorialUIBottomElement.Controls.None, true)
	_goal_element_1.hide()
	_goal_element_2.hide()
	
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause()
	
	_bottom_element.set_content("Try again by playing as the second\ntimeline another time!", TutorialUIBottomElement.Controls.None, true)
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause()
	remove_post_process_exception(_bottom_element)
	
	_character_manager._round_manager.round_index += 1
	_round_manager.disconnect("preparation_phase_started",self,"_on_prep_phase_started_round_3")
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
	var _error = _round_manager.connect("preparation_phase_started",self,"_on_prep_phase_started_round_3")
	_character_manager._on_timeline_picked(0,1)
	_character_manager._on_timeline_picked(1,1)
	_bottom_element.set_content("Start Round", TutorialUIBottomElement.Controls.Ready)
	_bottom_element.show()
	_character_manager.toggle_swapping(false)
	yield(_round_manager, "countdown_phase_started")
	_bottom_element.hide()
	yield(_round_manager, "game_phase_started")
	_enemy.set_position(Vector3(1200,0, 8))
	_bottom_element.show()
	_goal_element_1.show()
	_goal_element_2.show()
	_goal_element_2.set_content("Repeats", _ghost_manager._player_ghosts[0].get_body())
	if hit_data.perpetrator_team_id == _player.team_id and hit_data.type == HitData.HitType.WALL:
		_bottom_element.set_content("Melee!", TutorialUIBottomElement.Controls.Melee)
		_goal_element_1.set_content("Kill", _ghost_manager._enemy_ghosts[0].get_body())
	else:
		_bottom_element.set_content("Spawn Wall!", TutorialUIBottomElement.Controls.Shoot)
		_goal_element_1.set_content("Place here", _ghost_manager._enemy_ghosts[0].get_body())
	yield(_ghost_manager._player_ghosts[0], "respawned")
	# wait if we really aren't soft locked
	yield(get_tree(), "idle_frame")
	if  _ghost_manager._player_ghosts[0]._is_playing and not _ghost_manager._player_ghosts[0].currently_dying and not _ghost_manager._player_ghosts[0].currently_spawning: 
		_round_3_end_sequence()
