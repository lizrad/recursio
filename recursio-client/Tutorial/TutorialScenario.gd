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

var _round_starts := []
var _round_conditions := []
var _round_ends := []

# Currently active sub condition
var _current_sub_condition: int = 0

var _sub_conditions_starts := []
var _sub_conditions := []
var _sub_conditions_ends := []

onready var _goal_element_1 = get_node("TutorialUI/GoalElement1")
onready var _goal_element_2 = get_node("TutorialUI/GoalElement2")
onready var _bottom_element = get_node("TutorialUI/BottomElement")
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

func _ready():
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
	_player.block_switching = true
	
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


func _process(delta):
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
	_pause_post_processing.show()
	_paused = true
	_player.block_input = true
	_player.block_movement = true
	_round_manager.pause()
	if _enemyAI:
		_enemyAI.stop()

func unpause(enable_player_input: bool) -> void:
	_pause_post_processing.hide()
	_paused = false
	#because otherwise we will fire on unpause sometime
	yield(get_tree().create_timer(0.1), "timeout")
	_player.block_input = !enable_player_input
	_player.block_movement = !enable_player_input
	if _enemyAI:
		_enemyAI.start()
	_round_manager.unpause()

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
	_bottom_element.set_content("Good job!", TutorialUIBottomElement.Controls.None, true)
	pause()
	yield(_bottom_element, "continue_pressed")
	unpause(false)
	# this is needed so we don't instantly start the tutorial again because the accept input is not consumed
	call_deferred("emit_signal","scenario_completed")
	call_deferred("queue_free")
