extends Node
class_name CharacterManager

export var level_path: NodePath

# Scenes for instanciating 
var _player_scene = preload("res://Characters/Player.tscn")
var _ghost_scene = preload("res://Characters/Ghost.tscn")
var _player_ghost_scene = preload("res://Characters/PlayerGhost.tscn")
var _enemy_scene = preload("res://Characters/Enemy.tscn")


var _player: Player
var _enemy: Enemy

var _player_rpc_id: int

# Timeline index
var _player_ghosts: Array = []
var _enemy_ghosts: Array = []

# TODO: Move to GameManager?
onready var _game_result_screen = get_node("../GameResultScreen")
onready var _countdown_screen = get_node("../CountdownScreen")
onready var _level = get_node(level_path)

onready var _action_manager: ActionManager = get_node("ActionManager")

# TODO: Move to RoundManager
onready var _prep_phase_time: float = Constants.get_value("gameplay", "prep_phase_time")
var _prep_phase_in_progress = false
var _game_phase_in_progress = false

func _ready():	
	_game_result_screen.visible = false
	_countdown_screen.visible = false

	assert(Server.connect("spawning_player", self, "_spawn_player") == OK)
	assert(Server.connect("spawning_enemy", self, "_spawn_enemy") == OK)
	assert(Server.connect("despawning_enemy", self, "_despawn_enemy") == OK)
	assert(Server.connect("world_state_received", self, "_update_character_positions") == OK)
	assert(Server.connect("own_ghost_record_received", self, "_create_own_ghost") == OK)
	assert(Server.connect("enemy_ghost_record_received", self, "_create_enemy_ghost") == OK)
	assert(Server.connect("round_start_received",self, "_on_round_start_received") == OK)
	assert(Server.connect("round_end_received", self, "_on_round_ended_received") == OK)
	assert(Server.connect("capture_point_captured", self, "_on_capture_point_captured") == OK)
	assert(Server.connect("capture_point_team_changed", self, "_on_capture_point_team_changed") == OK)
	assert(Server.connect("capture_point_status_changed", self, "_on_capture_point_status_changed") == OK)
	assert(Server.connect("capture_point_capture_lost", self, "_on_capture_point_capture_lost") == OK)
	assert(Server.connect("game_result", self, "_on_game_result") == OK)
	assert(Server.connect("player_hit", self, "_on_player_hit") == OK)
	assert(Server.connect("ghost_hit", self, "_on_ghost_hit") == OK)
	assert(Server.connect("ghost_picks", self, "_on_ghost_picks") == OK)
	assert(Server.connect("player_action", self, "_on_player_action") == OK)

	set_physics_process(false)


func _reset():
	Logger.info("Full reset triggered.","gameplay")
	_player.reset()
	_player.spawn_point = _get_spawn_point(_player.team_id, 0)
	_player.move_to_spawn_point()
	
	_enemy.reset()
	_enemy.spawn_point = _get_spawn_point(_enemy.team_id, 0)
	_enemy.move_to_spawn_point()
	
	for timeline_index in _player_ghosts:
		_player_ghosts[timeline_index].queue_free()
	_player_ghosts.clear()
	
	for timeline_index in _enemy_ghosts:
		_enemy_ghosts[timeline_index].queue_free()
	_enemy_ghosts.clear()
	
	_level.reset()
	_action_manager.clear_action_instances()


func _get_spawn_point(team_id, timeline_index):
	return _level.get_spawn_points(team_id)[timeline_index]












