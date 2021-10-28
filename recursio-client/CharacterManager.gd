extends Node
class_name CharacterManager

export var level_path: NodePath

# Scenes for instanciating 
var _player_scene = preload("res://Characters/Player.tscn")
var _ghost_scene = preload("res://Characters/Ghost.tscn")
var _player_ghost_scene = preload("res://Characters/PlayerGhost.tscn")
var _enemy_scene = preload("res://Characters/Enemy.tscn")


var _player: Player
var _ememy: Enemy

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

	Server.connect("spawning_player", self, "_spawn_player")
	Server.connect("spawning_enemy", self, "_spawn_enemy")
	Server.connect("despawning_enemy", self, "_despawn_enemy")
	Server.connect("world_state_received", self, "_update_character_positions")
	Server.connect("own_ghost_record_received", self, "_create_own_ghost")
	Server.connect("enemy_ghost_record_received", self, "_create_enemy_ghost")
	Server.connect("round_start_received",self, "_on_round_start_received")
	Server.connect("round_end_received", self, "_on_round_ended_received")
	Server.connect("capture_point_captured", self, "_on_capture_point_captured" )
	Server.connect("capture_point_team_changed", self, "_on_capture_point_team_changed" )
	Server.connect("capture_point_status_changed", self, "_on_capture_point_status_changed" )
	Server.connect("capture_point_capture_lost", self, "_on_capture_point_capture_lost" )
	Server.connect("game_result", self, "_on_game_result" )
	Server.connect("player_hit", self, "_on_player_hit")
	Server.connect("ghost_hit", self, "_on_ghost_hit")
	Server.connect("ghost_picks", self, "_on_ghost_picks")
	Server.connect("player_action", self, "_on_player_action")

	set_physics_process(false)
