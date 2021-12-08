extends GhostBase
class_name Ghost

onready var _character_model : CharacterModel = get_node("KinematicBody/CharacterModel")

# TODO: move to Constants or make unique in any way
onready var _minimap_icon : MiniMapIcon = get_node("KinematicBody/MiniMapIcon")
onready var _minimap_icon_dead := preload("res://Resources/Icons/icon_dead_ghost_minimap.png")
onready var _minimap_icon_alive_hitscan := preload("res://Resources/Icons/icon_ghost_minimap_hitscan.png")
onready var _minimap_icon_alive_wall := preload("res://Resources/Icons/icon_ghost_minimap_wall.png")
onready var _minimap_icon_alive_hitscan_enemy := preload("res://Resources/Icons/icon_enemy_minimap_hitscan.png")
onready var _minimap_icon_alive_wall_enemy := preload("res://Resources/Icons/icon_enemy_minimap_wall.png")


var _minimap_alive

# OVERRIDE #
func init(action_manager, player_id, team_id, timeline_index, spawn_point) -> void:
	.init(action_manager, player_id, team_id, timeline_index, spawn_point)
	#var wall_index = Constants.get_value("ghosts", "wall_placing_timeline_index")
	# TODO: find a better way to detect enemy... maybe with groups or owning team or smth?
	#var friendly = "PlayerGhost" in name
	#if friendly:
	#	_minimap_alive = _minimap_icon_alive_hitscan if wall_index != timeline_index else _minimap_icon_alive_wall
	#else:
	#	_minimap_alive = _minimap_icon_alive_hitscan_enemy if wall_index != timeline_index else _minimap_icon_alive_wall_enemy

# OVERRIDE #
func start_playing(start_time: int) -> void:
	.start_playing(start_time)

# OVERRIDE #
# disable hit of base on client
func hit():
	pass

# Displays ghost as dead
# calls hit of base function triggered by server
func server_hit():
	if not is_record_data_set():
		return
	.hit()
	#_minimap_icon.set_texture(_minimap_icon_dead)

