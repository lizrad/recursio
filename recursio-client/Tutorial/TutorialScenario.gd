extends Node
class_name TutorialScenario

#warning-ignore:unused_signal
signal scenario_completed()

var show_ui: bool = true

# Number of rounds in this scenario
var _rounds: int = 0
# Currently active round in this scenario
var _current_round: int = 0


var _paused: bool = false

var _round_starts: Array = []
var _round_conditions: Array = []
var _round_ends: Array = []

# Currently active sub condition
var _current_sub_condition: int = 0

var _sub_conditions_starts: Array = []
var _sub_conditions: Array = []
var _sub_conditions_ends: Array = []

var _post_process_excepted_objects: Dictionary = {}

onready var _post_process_tool = get_node("TutorialUI/PausePostProcessing")
onready var _post_process_excepted = get_node("TutorialUI/PostProcessExcepted")
onready var _goal_element_1 = get_node("TutorialUI/PostProcessAffected/GoalElement1")
onready var _goal_element_2 = get_node("TutorialUI/PostProcessAffected/GoalElement2")
onready var _bottom_element: TutorialUIBottomElement = get_node("TutorialUI/PostProcessAffected/BottomElement")
onready var _pause_post_processing = get_node("TutorialUI/PausePostProcessing")
onready var _character_manager: CharacterManager = get_node("TutorialWorld/CharacterManager")
onready var _ghost_manager: ClientGhostManager = get_node("TutorialWorld/CharacterManager/GhostManager")
onready var _game_manager: GameManager = get_node("TutorialWorld/CharacterManager/GameManager")
onready var _round_manager: RoundManager = get_node("TutorialWorld/CharacterManager/RoundManager")
onready var _action_manager: ActionManager = get_node("TutorialWorld/CharacterManager/ActionManager")

var _level: Level
var _player: Player
var _enemy: Enemy
var _enemyAI: EnemyAI

func _ready() -> void:
	# setup level
	_level = get_node("TutorialWorld/LevelH")
	for capture_point in _level.get_capture_points():
		 capture_point.server_driven = false
	_game_manager.set_level(_level)
	
	# setup player
	_character_manager._on_spawn_player(0, Vector3.ZERO, 0)
	_character_manager.hide_player_button_overlay = true
	_player = _character_manager.get_player()
	_player.get_body().hide()
	
	_character_manager.toggle_trigger(ActionManager.Trigger.FIRE_START, false)
	_character_manager.toggle_trigger(ActionManager.Trigger.DEFAULT_ATTACK_START, false)
	_character_manager.toggle_trigger(ActionManager.Trigger.SPECIAL_MOVEMENT_START, false)
	
	_character_manager.toggle_movement(false)
	_character_manager.toggle_swapping(false)
	
	# setup enemy
	var spawn_point = _game_manager.get_spawn_point(1, 0).global_transform.origin
	_character_manager._on_spawn_enemy(1, spawn_point, 1)
	_enemy = _character_manager.get_enemy()
	_enemy.get_body().hide()
	_character_manager.enemy_is_server_driven = false
	
	# setup ui
	_goal_element_1.init(_player.get_camera())
	_goal_element_2.init(_player.get_camera())
	_goal_element_1.hide()
	_goal_element_2.hide()
	_bottom_element.hide()


func _process(delta: float) -> void:
	if _paused:
		return
	# stop the timer from moving
	if _character_manager._round_manager.get_current_phase() == RoundManager.Phases.GAME:
		_character_manager._round_manager._phase_deadline += delta * 1000
	
	# check subconditions:
	if _sub_conditions.size() > _current_sub_condition:
		if _sub_conditions[_current_sub_condition].call_func():
			_sub_conditions_ends[_current_sub_condition].call_func()
			_current_sub_condition  += 1
			if _sub_conditions.size() > _current_sub_condition:
				_sub_conditions_starts[_current_sub_condition].call_func()
	
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

func pause() -> void:
	Server.pause_local_clock()
	_pause_post_processing.show()
	_paused = true
	_character_manager.toggle_player_input_pause(true)
	if _enemyAI:
		_enemyAI.stop()

func unpause() -> void:
	Server.unpause_local_clock()
	_pause_post_processing.hide()
	_paused = false
	_character_manager.toggle_player_input_pause(false)
	if _enemyAI:
		_enemyAI.start()

func stop() -> void:
	unpause()
	queue_free()


# TODO: this does not seem to work correctly with non Control elements (but it is not really necessary for now)
func add_post_process_exception(object) -> void:
	var _global_transform
	if object is Spatial:
		_global_transform = object.global_transform
	_post_process_excepted_objects[object] = object.get_parent()
	object.get_parent().remove_child(object)
	_post_process_excepted.add_child(object)
	if object is Spatial:
		object.global_transform = _global_transform
	
func remove_post_process_exception(object) -> void:
	if not object in _post_process_excepted_objects:
		return 
	var _global_transform
	if object is Spatial:
		_global_transform = object.global_transform
	_post_process_excepted.remove_child(object)
	_post_process_excepted_objects[object].add_child(object)
	var _result = _post_process_excepted_objects.erase(object)
	if object is Spatial:
		object.global_transform = _global_transform

func toggle_player_input_pause(value: bool) -> void:
	_character_manager.toggle_player_input_pause(value)


func add_round_start_function(round_start_function: FuncRef) -> void:
	_round_starts.append(round_start_function)


func add_round_condition_function(round_condition_function: FuncRef) -> void:
	_round_conditions.append(round_condition_function)


func add_round_end_function(round_end_function: FuncRef) -> void:
	_round_ends.append(round_end_function)

func add_sub_condition(start: FuncRef, condition: FuncRef, end: FuncRef) -> void:
	_sub_conditions_starts.append(start)
	_sub_conditions.append(condition)
	_sub_conditions_ends.append(end)
	# immediately starting the first start function if this is the first subcondition
	if _sub_conditions.size() == 1:
		_sub_conditions_starts[0].call_func()


func clear_sub_conditions():
	_sub_conditions_starts.clear()
	_sub_conditions.clear()
	_sub_conditions_ends.clear()
	_current_sub_condition = 0


func _completed() -> void:
	_bottom_element.show()
	add_post_process_exception(_bottom_element)
	_bottom_element.set_content("Good job, you won!", TutorialUIBottomElement.Controls.None, true)
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause()
	PostProcess.chromatic_ab_strength = 0
	emit_signal("scenario_completed")
	queue_free()
