extends Spatial


enum Phases {
	ROUND1,
	ROUND2,
	DONE
}

var current_phase = Phases.ROUND1
var show_ui = true


func set_ui_visible(is_visible):
	$TutorialUI.visible = is_visible if show_ui else false


func _ready():
	var tutorial_text = get_node("TutorialUI/PanelContainer/TutorialText")
	var character_manager: CharacterManager = get_node("CharacterManager")	
	var ghost_manager: ClientGhostManager = get_node("CharacterManager/GhostManager")
	var game_manager: GameManager = get_node("CharacterManager/GameManager")
	var round_manager: RoundManager = get_node("CharacterManager/RoundManager")
	var action_manager: ActionManager =  get_node("CharacterManager/ActionManager")
	
	var level = get_node("LevelH")
	character_manager._game_manager.set_level(level)
	var scenario1: TutorialScenario_2 = TutorialScenario_2.new(tutorial_text, character_manager, ghost_manager, level)
	scenario1.connect("ui_toggled", self, "set_ui_visible")
	scenario1.connect("tree_exited", self, "on_scenario_completed")
	
	add_child(scenario1)
	
	character_manager._on_spawn_player(0, Vector3.ZERO, 0)
	character_manager.get_player().kb.visible = false
	character_manager.get_player().hide_button_overlay = true
	var spawn_point = game_manager.get_spawn_point(1, 0).global_transform.origin
	character_manager._on_spawn_enemy(1, spawn_point, 1)
	character_manager.enemy_is_server_driven = false
	character_manager.get_enemy().kb.visible = false
	
	ghost_manager.init(game_manager, round_manager, action_manager, character_manager)
	
	scenario1.start()


func on_scenario_completed() -> void:
	yield(get_tree().create_timer(2.0), "timeout")
	get_tree().change_scene("res://UI/Menus/StartMenu.tscn")






