extends Spatial


enum Phases {
	ROUND1,
	ROUND2,
	DONE
}

var current_phase = Phases.ROUND1
var show_text = true


func set_ui_visible(is_visible):
	$TutorialUI.visible = is_visible if show_text else false


func _ready():
	set_ui_visible(true)
	$CharacterManager/GameManager.set_level($LevelH)

	$TutorialUI/PanelContainer/TutorialText.text = "Welcome to the tutorial!"
	if show_text:
		yield(get_tree().create_timer(3), "timeout")
	
	$CharacterManager._on_spawn_player(0, Vector3.ZERO, 0)
	$CharacterManager.get_player().kb.visible = false
	
	$TutorialUI/PanelContainer/TutorialText.text = "The goal is to capture both points at once."
	if show_text:
		yield(get_tree().create_timer(4), "timeout")
	
	$CharacterManager.get_player().set_custom_view_target($LevelH.get_capture_points()[1])
	$TutorialUI/PanelContainer/TutorialText.text = "Try capturing this one!"
	if show_text:
		yield(get_tree().create_timer(3), "timeout")
	
	$CharacterManager.get_player().follow_camera()
	set_ui_visible(false)
	
	$CharacterManager.get_player().kb.visible = true
	
	$CharacterManager._on_spawn_enemy(1, Vector3.FORWARD * 10.0)
	$CharacterManager.get_enemy().kb.visible = false
	$CharacterManager/RoundManager._start_game()


func _process(delta):
	if current_phase == Phases.ROUND1:
		_update_phase1()
	elif current_phase == Phases.ROUND2:
		_update_phase2()
	elif current_phase == Phases.DONE:
		pass


func _update_phase1():
	if $LevelH.get_capture_points()[1]._capture_progress >= 0.9 \
			and $LevelH.get_capture_points()[1]._capture_progress < 1.0:
		$LevelH.get_capture_points()[1]._capture_progress = 1.0
		set_ui_visible(true)
		$TutorialUI/PanelContainer/TutorialText.text = "Nice!"
		
		if show_text:
			yield(get_tree().create_timer(3), "timeout")
		
		$CharacterManager/RoundManager.round_index += 1
		$CharacterManager/RoundManager.switch_to_phase(RoundManager.Phases.PREPARATION)
		$CharacterManager._on_player_ghost_record_received(0, $CharacterManager.get_player().get_record_data())
		current_phase = Phases.ROUND2
		
		$TutorialUI/PanelContainer/TutorialText.text = "Now try capturing both points."
		if show_text:
			yield(get_tree().create_timer(3), "timeout")
		$TutorialUI/PanelContainer/TutorialText.text = "Your past self will help you!"


func _update_phase2():
	if $LevelH.get_capture_points()[1]._capture_progress >= 0.9 \
			and $LevelH.get_capture_points()[1]._capture_progress < 1.0 \
			and $LevelH.get_capture_points()[0]._capture_progress >= 0.9 \
			and $LevelH.get_capture_points()[0]._capture_progress < 1.0:
		$LevelH.get_capture_points()[0]._capture_progress = 1.0
		$LevelH.get_capture_points()[1]._capture_progress = 1.0
		
		set_ui_visible(true)
		$TutorialUI/PanelContainer/TutorialText.text = "Good job!"
		
		current_phase = Phases.DONE
		
		yield(get_tree().create_timer(2.0), "timeout")
		get_tree().change_scene("res://UI/Menus/StartMenu.tscn")
