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
	var character_manager = get_node("CharacterManager")	
	var level = get_node("LevelH")
	var scenario1: TutorialScenario_2 = TutorialScenario_2.new(tutorial_text, character_manager, level)
	scenario1.connect("ui_toggled", self, "set_ui_visible")
	scenario1.connect("tree_exited", self, "on_scenario_completed")
	add_child(scenario1)


func on_scenario_completed() -> void:
	yield(get_tree().create_timer(2.0), "timeout")
	get_tree().change_scene("res://UI/Menus/StartMenu.tscn")






