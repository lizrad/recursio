extends GhostBase
class_name Ghost

onready var _character_model : CharacterModel = get_node("KinematicBody/CharacterModel")

onready var _minimap_icon : MiniMapIcon = get_node("KinematicBody/MiniMapIcon")
onready var _minimap_icon_alive := load("res://Resources/Icons/icon_ghost_minimap.png")
onready var _minimap_icon_dead := load("res://Resources/Icons/icon_dead_ghost_minimap.png")


func ghost_init(action_manager, record_data: RecordData) -> void:
	.ghost_base_init(action_manager, record_data)
	_character_model._set_color_scheme( "enemy_ghost", record_data.timeline_index)
	

# OVERRIDE #
func start_playing(start_time: int) -> void: 
	.start_playing(start_time)
	_minimap_icon.set_texture(_minimap_icon_alive)

# Displays ghost as dead and triggers the base classes hit function
# OVERRIDE #
func hit():
	.hit()
	_minimap_icon.set_texture(_minimap_icon_dead)
	#_mesh.rotate_z(90)
