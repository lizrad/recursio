extends TutorialScenario
class_name TutorialScenario_2

var _character_manager: CharacterManager
var _ghost_manager: ClientGhostManager
var _level: Level


func _init(tutorial_text, character_manager, ghost_manager, level).(tutorial_text):
	_character_manager = character_manager
	_ghost_manager = ghost_manager
	_level = level


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


func _started_round_1():
	_toggle_ui(true)
	_tutorial_text.typing_text = "This scenario will teach you about enemies. Try to capture the lower capture point again."
		
	_character_manager.get_player().follow_camera()
	_character_manager.get_player().kb.visible = true
	_character_manager.get_player().block_movement = true
	_character_manager.get_player().block_input = true
	_character_manager.get_enemy().kb.visible = true
	_character_manager.get_enemy().block_movement = false
	
	_character_manager.get_player().connect("client_hit", self, "_on_player_hit")
	_character_manager.get_enemy().connect("client_hit", self, "_on_enemy_hit")
	
	var enemyAI: EnemyAI = EnemyAI.new(_character_manager.get_enemy())
	enemyAI.add_waypoint(Vector2(-12, 8))
	enemyAI.add_waypoint(Vector2(-5, 5))
	
	enemyAI.set_character_to_shoot(_character_manager.get_player())
	
	add_child(enemyAI)
	enemyAI.start()
	
	_character_manager._round_manager._start_game()
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.GAME)
	_character_manager.get_player().block_movement = true
	yield(_tutorial_text, "typing_completed")
	_character_manager.get_player().block_movement = false
	yield(get_tree().create_timer(3), "timeout")
	_toggle_ui(false)
	
	# Wait until player gets hit
	yield(_character_manager.get_player(), "client_hit")
	_character_manager.get_player().block_input = false
	
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


func _started_round_2() -> void:
	_toggle_ui(true)
	_tutorial_text.typing_text = "Now watch what happens with your ghost."
	
	_level.get_capture_points()[1]._capture_progress = 0.0
	yield(get_tree().create_timer(_character_manager._round_manager._preparation_phase_time + 0.1), "timeout")
	_character_manager.get_player().move_camera_to_overview()
	_character_manager.get_player().block_movement = true
	_character_manager.get_player().kb.visible = false


func _check_completed_round_2() -> bool:
	return _ghost_manager._player_ghosts[0].currently_dying


func _completed_round_2() -> void:
	
	_toggle_ui(true)
	_tutorial_text.typing_text = "After a ghost is hit, he is dead for the round and will not come back like the player."


func _started_round_3() -> void:
	
	yield(_tutorial_text, "typing_completed")
	yield(get_tree().create_timer(2), "timeout")
	
	_tutorial_text.typing_text = "Try to capture both points by rescuing your ghost."
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


func _on_enemy_hit():
	_character_manager.get_enemy().server_hit(_character_manager.get_player())


func _on_player_hit():
	_character_manager.get_player().server_hit(_character_manager.get_enemy())




