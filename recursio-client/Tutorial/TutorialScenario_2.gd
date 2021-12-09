extends TutorialScenario
class_name TutorialScenario_2

var _character_manager: CharacterManager
var _level: Level


func _init(tutorial_text, character_manager, level).(tutorial_text):
	_character_manager = character_manager
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
	
	start()


func _started_round_1():
	_toggle_ui(true)
	_character_manager._game_manager.set_level(_level)
	
	_character_manager._on_spawn_player(0, Vector3.ZERO, 0)
	_character_manager.get_player().kb.visible = false
	_character_manager.get_player().hide_button_overlay = true
	
	_tutorial_text.typing_text = "This scenario will teach you about enemies. Try to capture the lower capture point again."
	
	
	
	_character_manager.get_player().follow_camera()
	
	
	_character_manager.get_player().kb.visible = true
	
	_character_manager._on_spawn_enemy(1, Vector3.FORWARD * 10.0, 0)
	_character_manager.get_enemy().kb.visible = false
	_character_manager._round_manager._start_game()
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.GAME)
	
	yield(_tutorial_text, "typing_completed")
	yield(get_tree().create_timer(3), "timeout")
	_toggle_ui(false)
	
	# Wait until player gets hit
	yield(_character_manager.get_player(), "hit")
	
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
	_character_manager._on_player_ghost_record_received(0, _character_manager.get_player().get_record_data())


func _started_round_2() -> void:
	_toggle_ui(true)
	_tutorial_text.typing_text = "Now watch what happens with your ghost."
	
	_level.get_capture_points()[1]._capture_progress = 0.0
	yield(get_tree().create_timer(_character_manager._round_manager._preparation_phase_time + 0.1), "timeout")
	_character_manager.get_player().move_camera_to_overview()
	_character_manager.get_player().block_movement = true
	_character_manager.get_player().kb.visible = false


func _check_completed_round_2() -> bool:
	return _character_manager._player_ghosts[0].currently_dying


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








