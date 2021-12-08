extends TutorialScenario
class_name TutorialScenario_1

var _character_manager: CharacterManager
var _level: Level


func _init(tutorial_text, character_manager, level).(tutorial_text):
	_character_manager = character_manager
	_level = level


func _ready():
	_rounds = 2
	add_round_start_function(funcref(self, "_started_round_1"))
	add_round_condition_function(funcref(self, "_check_completed_round_1"))
	add_round_end_function(funcref(self, "_completed_round_1"))
	
	add_round_start_function(funcref(self, "_started_round_2"))
	add_round_condition_function(funcref(self, "_check_completed_round_2"))
	add_round_end_function(funcref(self, "_completed_round_2"))
	
	start()


func _started_round_1():
	_toggle_ui(true)
	_character_manager._game_manager.set_level(_level)

	_tutorial_text.typing_text = "Welcome to the tutorial!"
	if show_ui:
		yield(get_tree().create_timer(3), "timeout")
	
	_character_manager._on_spawn_player(0, Vector3.ZERO, 0)
	_character_manager.get_player().kb.visible = false
	_character_manager.get_player().hide_button_overlay = true
	
	_tutorial_text.typing_text = "The goal is to capture both points at once."
	if show_ui:
		yield(get_tree().create_timer(4), "timeout")
	
	_character_manager.get_player().set_custom_view_target(_level.get_capture_points()[1])
	_tutorial_text.typing_text = "Try capturing this one!"
	if show_ui:
		yield(get_tree().create_timer(3), "timeout")
	
	_character_manager.get_player().follow_camera()
	_toggle_ui(false)
	
	_character_manager.get_player().kb.visible = true
	
	_character_manager._on_spawn_enemy(1, Vector3.FORWARD * 10.0, 0)
	_character_manager.get_enemy().kb.visible = false
	_character_manager._round_manager._start_game()


func _check_completed_round_1() -> bool:
	return _level.get_capture_points()[1]._capture_progress >= 0.9


func _completed_round_1() -> void:
	_level.get_capture_points()[1]._capture_progress = 1.0
	_toggle_ui(true)
	_tutorial_text.typing_text = "Nice!"


func _started_round_2() -> void:
	if show_ui:
		yield(get_tree().create_timer(3), "timeout")
	
	_character_manager._round_manager.round_index += 1
	_character_manager._round_manager.switch_to_phase(RoundManager.Phases.PREPARATION)
	_character_manager._on_player_ghost_record_received(0, _character_manager.get_player().get_record_data())
	
	_tutorial_text.typing_text = "Now try capturing both points."
	if show_ui:
		yield(get_tree().create_timer(3), "timeout")
	_tutorial_text.typing_text = "Your past self will help you!"


func _check_completed_round_2() -> bool:
	return _level.get_capture_points()[1]._capture_progress >= 0.9 \
			and _level.get_capture_points()[0]._capture_progress >= 0.9 \

func _completed_round_2() -> void:
	_level.get_capture_points()[0]._capture_progress = 1.0
	_level.get_capture_points()[1]._capture_progress = 1.0
	
	_toggle_ui(true)
	_tutorial_text.typing_text = "Good job!"
