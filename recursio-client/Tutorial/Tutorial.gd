extends Control
class_name Tutorial

signal scenario_started()
signal scenario_completed()
signal btn_back_pressed()

export(Array, PackedScene) var tutorial_scenes: Array = []

onready var _btn_tutorial_1: Button = get_node("TutorialMenu/Tutorial1")
onready var _btn_tutorial_2: Button = get_node("TutorialMenu/Tutorial2")
onready var _btn_back: Button = get_node("TutorialMenu/Btn_Back")

var _scenario: TutorialScenario

func _ready():
	var _error = _btn_tutorial_1.connect("pressed", self, "start_scenario", [0])
	_error = _btn_tutorial_2.connect("pressed", self, "start_scenario", [1])
	_error = _btn_back.connect("pressed", self, "_on_back_pressed")

# OVERRIDE #
func show() -> void:
	_btn_tutorial_1.grab_focus()
	.show()


func start_scenario(scenario_index) -> void:
	_btn_tutorial_1.disabled = true
	_btn_tutorial_2.disabled = true
	_scenario = tutorial_scenes[scenario_index].instance()
	add_child(_scenario)
	_scenario.init()
	
	var _error = _scenario.connect("scenario_completed", self, "on_scenario_completed")
	
	emit_signal("scenario_started")
	_scenario.start()


func stop_scenario() -> void:
	_btn_tutorial_1.disabled = false
	_btn_tutorial_2.disabled = false
	_scenario.stop()


func on_scenario_completed() -> void:
	_btn_tutorial_1.disabled = false
	_btn_tutorial_2.disabled = false
	emit_signal("scenario_completed")


func _on_back_pressed() -> void:
	emit_signal("btn_back_pressed")





