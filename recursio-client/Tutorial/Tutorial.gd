extends Control
class_name Tutorial

signal scenario_completed()
signal btn_back_pressed()

export(Array, PackedScene) var tutorial_scenes: Array = []

onready var _btn_tutorial_1: Button = get_node("TutorialMenu/Tutorial1")
onready var _btn_tutorial_2: Button = get_node("TutorialMenu/Tutorial2")
onready var _btn_back: Button = get_node("TutorialMenu/Btn_Back")

onready var _click_sound: AudioStreamPlayer = get_node("../ClickSound")
onready var _back_sound: AudioStreamPlayer = get_node("../BackSound")


func _ready():
	_btn_tutorial_1.connect("pressed", self, "start_scenario", [0])
	_btn_tutorial_2.connect("pressed", self, "start_scenario", [1])
	_btn_back.connect("pressed", self, "_on_back_pressed")

# OVERRIDE #
func show() -> void:
	_btn_tutorial_1.grab_focus()
	.show()


func start_scenario(scenario_index) -> void:
	_click_sound.play()
	_btn_tutorial_1.disabled = true
	_btn_tutorial_2.disabled = true
	var scenario: TutorialScenario = tutorial_scenes[scenario_index].instance()
	add_child(scenario)
	scenario.init()
	
	scenario.connect("scenario_completed", self, "on_scenario_completed")
	
	scenario.start()


func on_scenario_completed() -> void:
	_btn_tutorial_1.disabled = false
	_btn_tutorial_2.disabled = false
	emit_signal("scenario_completed")


func _on_back_pressed() -> void:
	_back_sound.play()
	emit_signal("btn_back_pressed")





