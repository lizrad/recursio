extends Spatial


func _ready():
#	$Player.player_init($CharacterManager/ActionManager, $CharacterManager/RoundManager)
#	$Player.block_movement = false

	$TutorialUI/PanelContainer/TutorialText.text = "Welcome to the tutorial!"
	yield(get_tree().create_timer(5.0), "timeout")
	
	$CharacterManager._on_spawn_player(0, Vector3.ZERO, 0)
	$CharacterManager.get_player().kb.visible = false
	
	$TutorialUI/PanelContainer/TutorialText.text = "The goal is to capture both points at once."
	yield(get_tree().create_timer(5.0), "timeout")
	
	$TutorialUI/PanelContainer/TutorialText.text = "Try capturing this one!"
	yield(get_tree().create_timer(5.0), "timeout")
	
	$TutorialUI/PanelContainer/TutorialText.visible = false
	
	$CharacterManager.get_player().kb.visible = true
	
	$CharacterManager._on_spawn_enemy(0, Vector3.FORWARD * 10.0)
	$CharacterManager/RoundManager._start_game()
