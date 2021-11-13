extends GhostBase
class_name Ghost

onready var _character_model : CharacterModel = get_node("KinematicBody/CharacterModel")

# TODO: move to Constants or make unique in any way
onready var _minimap_icon : MiniMapIcon = get_node("KinematicBody/MiniMapIcon")
onready var _minimap_icon_dead := load("res://Resources/Icons/icon_dead_ghost_minimap.png")
onready var _minimap_icon_alive_hitscan := load("res://Resources/Icons/icon_ghost_minimap_hitscan.png")
onready var _minimap_icon_alive_wall := load("res://Resources/Icons/icon_ghost_minimap_wall.png")
onready var _minimap_icon_alive_hitscan_enemy := load("res://Resources/Icons/icon_enemy_minimap_hitscan.png")
onready var _minimap_icon_alive_wall_enemy := load("res://Resources/Icons/icon_enemy_minimap_wall.png")


var _minimap_alive

func ghost_init(action_manager, record_data: RecordData) -> void:
	.ghost_base_init(action_manager, record_data)

	var wall_index = Constants.get_value("ghosts", "wall_placing_timeline_index")
	# TODO: find a better way to detect enemy... maybe with groups or owning team or smth?
	var friendly = "PlayerGhost" in name
	if friendly:
		_minimap_alive = _minimap_icon_alive_hitscan if wall_index != timeline_index else _minimap_icon_alive_wall
		#_character_model._set_color_scheme("player_ghost", record_data.timeline_index)
	else:
		_minimap_alive = _minimap_icon_alive_hitscan_enemy if wall_index != timeline_index else _minimap_icon_alive_wall_enemy
		#_character_model._set_color_scheme("enemy_ghost", record_data.timeline_index)

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
	.hit()
	# TODO: apply death animation and mesh
	_minimap_icon.set_texture(_minimap_icon_dead)
	_character_model.visible = false

func enable_body():
	_kb.visible = true

	_minimap_icon.set_texture(_minimap_alive)
	_character_model.visible = true


func disable_body():
	_kb.visible = false
