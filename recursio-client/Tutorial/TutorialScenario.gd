extends Node
class_name TutorialScenario

signal scenario_completed()

var show_ui: bool = true

# Number of rounds in this scenario
var _rounds: int = 0
# Currently active round in this scenario
var _current_round: int = 0

var _completion_delay: float = 0

var _round_starts := []
var _round_conditions := []
var _round_ends := []

var _tutorial_text: TypingTextLabel

var _character_manager: CharacterManager
var _ghost_manager: ClientGhostManager
var _game_manager: GameManager
var _round_manager: RoundManager
var _action_manager: ActionManager

var _level: Level


func _ready():
	_tutorial_text = get_node("TutorialUI/PanelContainer/TutorialText")
	_character_manager = get_node("TutorialWorld/CharacterManager")
	_ghost_manager = get_node("TutorialWorld/CharacterManager/GhostManager")
	_game_manager = get_node("TutorialWorld/CharacterManager/GameManager")
	_round_manager = get_node("TutorialWorld/CharacterManager/RoundManager")
	_action_manager =  get_node("TutorialWorld/CharacterManager/ActionManager")
	
	_level = get_node("TutorialWorld/LevelH")
	_game_manager.set_level(_level)


func _process(delta):
	if _character_manager._round_manager.get_current_phase() == RoundManager.Phases.GAME:
		_character_manager._round_manager._phase_deadline += delta * 1000
	
	if not _round_conditions[_current_round].call_func():
		return
	
	_round_ends[_current_round].call_func()
	_current_round += 1
	
	# Are we done with the scenario?
	if _current_round >= _rounds:
		set_process(false)
		_completed()
		return
	
	# Call round start for new round
	_round_starts[_current_round].call_func()


func init():
	_ghost_manager.init(_game_manager, _round_manager, _action_manager, _character_manager)


func start():
	_round_starts[_current_round].call_func()


func add_round_start_function(round_start_function: FuncRef):
	_round_starts.append(round_start_function)


func add_round_condition_function(round_condition_function: FuncRef):
	_round_conditions.append(round_condition_function)


func add_round_end_function(round_end_function: FuncRef):
	_round_ends.append(round_end_function)


func _toggle_ui(show: bool) -> void:
	$TutorialUI.visible = show if show_ui else false


func _completed() -> void:
	yield(get_tree().create_timer(_completion_delay), "timeout")
	emit_signal("scenario_completed")
	queue_free()
