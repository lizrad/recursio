extends Spatial


func _ready():
#	$Player.player_init($CharacterManager/ActionManager, $CharacterManager/RoundManager)
#	$Player.block_movement = false

	$TutorialUI/PanelContainer/TutorialText.text = "Welcome to the tutorial!"
	yield(get_tree().create_timer(3.0), "timeout")
	
	$CharacterManager._on_spawn_player(0, Vector3.ZERO, 0)
	$CharacterManager.get_player().kb.visible = false
	
	$TutorialUI/PanelContainer/TutorialText.text = "The goal is to capture both points at once."
	yield(get_tree().create_timer(4.0), "timeout")
	
	$CharacterManager.get_player().set_custom_view_target($LevelH.get_capture_points()[1])
	$TutorialUI/PanelContainer/TutorialText.text = "Try capturing this one!"
	yield(get_tree().create_timer(3.0), "timeout")
	
	$CharacterManager.get_player().follow_camera()
	$TutorialUI/PanelContainer/TutorialText.visible = false
	
	$CharacterManager.get_player().kb.visible = true
	
	$CharacterManager._on_spawn_enemy(0, Vector3.FORWARD * 10.0)
	$CharacterManager/RoundManager._start_game()


func _process(delta):
	if $LevelH.get_capture_points()[1]._capture_progress >= 0.9 \
			and $LevelH.get_capture_points()[1]._capture_progress < 1.0:
		$LevelH.get_capture_points()[1]._capture_progress = 1.0
		$TutorialUI/PanelContainer/TutorialText.visible = true
		$TutorialUI/PanelContainer/TutorialText.text = "Nice!"
		
		yield(get_tree().create_timer(3.0), "timeout")
		
		$CharacterManager/RoundManager.round_index += 1
		$CharacterManager/RoundManager.switch_to_phase(RoundManager.Phases.PREPARATION)
		$CharacterManager._on_player_ghost_record_received(0, $CharacterManager.get_player().get_record_data())
		
		$TutorialUI/PanelContainer/TutorialText.text = "Now try capturing the other point too."
