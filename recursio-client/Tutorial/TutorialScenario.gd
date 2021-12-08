extends Node
class_name TutorialScenario

signal ui_toggled(show)

var show_ui: bool = true

# Number of rounds in this scenario
var _rounds: int = 0
# Currently active round in this scenario
var _current_round: int = 1

var _tutorial_text: RichTextLabel


func _init(tutorial_text: RichTextLabel):
	_tutorial_text = tutorial_text


func _process(delta):
	if call("_check_completed_round_" + str(_current_round)):
		call("_completed_round_" + str(_current_round))
		_current_round += 1
		# Are we done with the scenario?
		if _current_round > _rounds:
			queue_free()
			set_process(false)
			return
		call("_started_round_" + str(_current_round))
	
	call("_update_round_" + str(_current_round))


func _toggle_ui(show: bool) -> void:
	emit_signal("ui_toggled", show if show_ui else false)


func _started_round_1() -> void:
	pass


# Example method for round 1 end condition
func _check_completed_round_1() -> bool:
	return false


# Example method for round 1 update
func _update_round_1() -> void:
	pass


# Example method for on round 1 completion
func _completed_round_1() -> void:
	pass


