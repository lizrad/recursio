extends TutorialScenario
class_name TutorialScenario_2

var _player: Player
var _enemy: Enemy


func _ready():
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
	
	_character_manager._on_spawn_player(0, Vector3.ZERO, 0)
	_character_manager.get_player().kb.visible = false
	_character_manager.get_player().hide_button_overlay = true
	var spawn_point = _game_manager.get_spawn_point(1, 0).global_transform.origin
	_character_manager._on_spawn_enemy(1, spawn_point, 1)
	_character_manager.enemy_is_server_driven = false
	_character_manager.get_enemy().kb.visible = false


func _started_round_1():	
	_toggle_ui(true)
	_tutorial_text.typing_text = "This scenario will teach you about enemies. Try to capture the lower capture point again."
	
	_player = _character_manager.get_player()
	_enemy = _character_manager.get_enemy()
	
	_player.follow_camera()
	_player.kb.visible = true
	_player.block_movement = true
	_player.block_input = true
	_enemy.kb.visible = true
	_enemy.block_movement = false
	
	_player.connect("client_hit", self, "_on_player_hit")
	_enemy.connect("client_hit", self, "_on_enemy_hit")
	
	var enemyAI: EnemyAI = EnemyAI.new(_enemy)
	enemyAI.add_waypoint(Vector2(-12, 8))
	enemyAI.add_waypoint(Vector2(-5, 5))
	
	enemyAI.set_character_to_shoot(_player)
	
	add_child(enemyAI)
	enemyAI.start()
	
	_character_manager._round_manager._start_game()
	_player.block_movement = true
	yield(_tutorial_text, "typing_completed")
	_player.block_movement = false
	yield(get_tree().create_timer(3), "timeout")
	_toggle_ui(false)
	
	# Wait until player gets hit
	yield(_player, "client_hit")
	_player.block_input = false
	
	_toggle_ui(true)
	_tutorial_text.typing_text = "When a player gets hit, he will be send back to the spawnpoint."
	
	yield(_tutorial_text, "typing_completed")
	yield(get_tree().create_timer(2), "timeout")
	
	_tutorial_text.typing_text = "Try again! But this time, shoot the enemy before he can shoot you."
	
	yield(_tutorial_text, "typing_completed")
	yield(get_tree().create_timer(2), "timeout")
	_toggle_ui(false)


func _check_completed_round_1() -> bool:
	return _level.get_capture_points()[1]._capture_progress >= 0.9


func _completed_round_1() -> void:
	_level.get_capture_points()[1]._capture_progress = 1.0
	_character_manager._round_manager.round_index += 1
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
	_enemy.kb.visible = false
	_player.kb.visible = false
	_player.block_movement = true


func _started_round_2() -> void:
	for ghost in _ghost_manager._ghosts:
		if ghost.team_id == 0:
			ghost.connect("client_hit", self, "_on_ghost_hit_soft_lock", [ghost])
		else:
			ghost.connect("client_hit", self, "_on_ghost_hit", [ghost])
	
	
	_toggle_ui(true)
	_tutorial_text.typing_text = "Now watch what happens with your ghost."
	
	_level.get_capture_points()[1]._capture_progress = 0.0
	yield(get_tree().create_timer(_character_manager._round_manager._preparation_phase_time + 0.1), "timeout")
	_player.move_camera_to_overview()


func _check_completed_round_2() -> bool:
	return _ghost_manager._player_ghosts[0].currently_dying


func _completed_round_2() -> void:
	
	_toggle_ui(true)
	_tutorial_text.typing_text = "After a ghost is hit, he is dead for the round and will not come back like the player."


func _started_round_3() -> void:
	
	yield(_tutorial_text, "typing_completed")
	yield(get_tree().create_timer(2), "timeout")
	_toggle_ui(true)
	_tutorial_text.typing_text = "This round, instead of shooting, you can place 2 walls. Ghosts that touch these walls die."
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
	_player.kb.visible = true
	_enemy.kb.visible = true
	yield(_tutorial_text, "typing_completed")
	yield(get_tree().create_timer(2), "timeout")	
	
	_tutorial_text.typing_text = "Try to capture both points by rescuing your ghost!"
	yield(_tutorial_text, "typing_completed")
	yield(get_tree().create_timer(2), "timeout")
	
	_toggle_ui(false)


func _check_completed_round_3() -> bool:
	return _level.get_capture_points()[1]._capture_progress >= 0.9 \
			and _level.get_capture_points()[0]._capture_progress >= 0.9 \


func _completed_round_3() -> void:
	_level.get_capture_points()[0]._capture_progress = 1.0
	_level.get_capture_points()[1]._capture_progress = 1.0
	
	_toggle_ui(true)
	_tutorial_text.typing_text = "Good job!"


func _on_player_hit(perpetrator):
	_player.server_hit(perpetrator)


func _on_enemy_hit(perpetrator):
	_enemy.server_hit(perpetrator)


func _on_ghost_hit(perpetrator, ghost: Ghost):
	if ghost is PlayerGhost:
		ghost.toggle_visible_light = false
	ghost.server_hit(perpetrator)


func _on_ghost_hit_soft_lock(perpetrator, ghost: Ghost):
	ghost.server_hit(perpetrator)
	_toggle_ui(true)
	_tutorial_text.typing_text = "Oh no, your ghost died! Try again."
	yield(_tutorial_text, "typing_completed")
	yield(get_tree().create_timer(2), "timeout")
	_toggle_ui(false)
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
