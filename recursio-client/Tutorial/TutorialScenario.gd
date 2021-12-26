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

onready var _goal_element_1 = get_node("TutorialUI/GoalElement1")
onready var _goal_element_2 = get_node("TutorialUI/GoalElement2")
onready var _bottom_element = get_node("TutorialUI/BottomElement")
onready var _tutorial_text: TypingTextLabel = get_node("TutorialUI/BottomElement/PanelContainer/TutorialText")
onready var _character_manager: CharacterManager = get_node("TutorialWorld/CharacterManager")
onready var _ghost_manager: ClientGhostManager = get_node("TutorialWorld/CharacterManager/GhostManager")
onready var _game_manager: GameManager = get_node("TutorialWorld/CharacterManager/GameManager")
onready var _round_manager: RoundManager = get_node("TutorialWorld/CharacterManager/RoundManager")
onready var _action_manager: ActionManager = get_node("TutorialWorld/CharacterManager/ActionManager")

var _level: Level


func _ready():
	_level = get_node("TutorialWorld/LevelH")
	_game_manager.set_level(_level)
	_bottom_element.hide()
	_goal_element_1.hide()
	_goal_element_2.hide()


func _process(delta):
	# stop the timer from moving
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


func init() -> void:
	_ghost_manager.init(_game_manager, _round_manager, _action_manager, _character_manager)


func start() -> void:
	_round_starts[_current_round].call_func()


func stop() -> void:
	queue_free()


func toggle_player_input(disabled: bool) -> void:
	_character_manager.toggle_player_input(disabled)


func add_round_start_function(round_start_function: FuncRef) -> void:
	_round_starts.append(round_start_function)


func add_round_condition_function(round_condition_function: FuncRef) -> void:
	_round_conditions.append(round_condition_function)


func add_round_end_function(round_end_function: FuncRef) -> void:
	_round_ends.append(round_end_function)


func _toggle_ui(show: bool) -> void:
	if _tutorial_text.typing_completed:
		$TutorialUI.visible = show if show_ui else false


func _completed() -> void:
	yield(get_tree().create_timer(_completion_delay), "timeout")
	emit_signal("scenario_completed")
	queue_free()
