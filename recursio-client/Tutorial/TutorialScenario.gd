extends Node
class_name TutorialScenario

signal ui_toggled(show)

var show_ui: bool = true

# Number of rounds in this scenario
var _rounds: int = 0
# Currently active round in this scenario
var _current_round: int = 0

var _tutorial_text: TypingTextLabel

var _round_starts := []
var _round_conditions := []
var _round_ends := []



func _init(tutorial_text):
	_tutorial_text = tutorial_text


func _process(delta):
	if not _round_conditions[_current_round].call_func():
		return
	
	_round_ends[_current_round].call_func()
	_current_round += 1
	
	# Are we done with the scenario?
	if _current_round >= _rounds:
		queue_free()
		set_process(false)
		return
	
	# Call round start for new round
	_round_starts[_current_round].call_func()


func start():
	_round_starts[_current_round].call_func()


func add_round_start_function(round_start_function: FuncRef):
	_round_starts.append(round_start_function)


func add_round_condition_function(round_condition_function: FuncRef):
	_round_conditions.append(round_condition_function)


func add_round_end_function(round_end_function: FuncRef):
	_round_ends.append(round_end_function)


func _toggle_ui(show: bool) -> void:
	emit_signal("ui_toggled", show if show_ui else false)

