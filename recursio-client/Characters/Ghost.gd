extends GhostBase
class_name Ghost

onready var _mesh : MeshInstance = get_node("Mesh_Body")

onready var _minimap_icon : MiniMapIcon = get_node("MiniMapIcon")
onready var _minimap_icon_alive := load("res://Resources/Icons/icon_ghost_minimap.png")
onready var _minimap_icon_dead := load("res://Resources/Icons/icon_dead_ghost_minimap.png")

# OVERRIDE #
func _init(action_manager : ActionManager, record_data: RecordData, color: Color)\
.(action_manager, record_data):
	
	_mesh.material_override.set_shader_param("color", color)
	

# OVERRIDE #
func start_playing(start_time: int) -> void: 
	.start_playing(start_time)
	_minimap_icon.set_texture(_minimap_icon_alive)

# Displays ghost as dead and triggers the base classes hit function
# OVERRIDE #
func hit():
	.hit()
	_minimap_icon.set_texture(_minimap_icon_dead)
	_mesh.rotate_z(90)
