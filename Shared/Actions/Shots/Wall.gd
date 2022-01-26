extends StaticBody
class_name Wall

export var animation_time:= 3.0

onready var _mesh_pivot = get_node("MeshPivot")
onready var _mesh_instance = get_node("MeshPivot/MeshInstance")
var _time_since_spawn := 0.0
var placed_by_body
var round_index
var _owning_player

onready var _server: Server = get_node("/root/Server")

var needs_server_confirmation = false
# TODO: this value is very random, figure out a good one
var _timer_confirmation_deadline = 2
var confirmed = false

func _init() -> void:
	Logger.info("_init action", "Wall")

#adapted from: https://easings.net/#easeOutElastic
func ease_out_elastic(x: float, wobble: float) -> float:
	var c4 = (2.0 * PI) / 3.0
	return 0.0 if x == 0 else (1.0 if x == 1 else  pow(2.0, -10.0 * x) * sin((x * wobble - 0.75) * c4) + 1.0);

func _process(delta):
	_time_since_spawn += delta
	if _time_since_spawn <= animation_time:
		var ratio = min(1, _time_since_spawn/animation_time)
		var remapped_ratio = ease_out_elastic(ratio,15.0)
		_mesh_pivot.scale = Vector3(1, remapped_ratio, 1)
	else:
		_mesh_pivot.scale = Vector3(1, 1, 1)
	
	
	if needs_server_confirmation and _server.is_connection_active:
		if not confirmed:
			if _time_since_spawn > _timer_confirmation_deadline:
				_owning_player.wall_despawned(self)
				free()

func _ready():
	var _error = $KillGhostArea.connect("body_entered", self, "handle_hit") 


func initialize(owning_player) -> void:
	initialize_visual(owning_player)
	placed_by_body = owning_player
	owning_player.wall_spawned(self)
	_owning_player = owning_player
	round_index = owning_player.round_index


func initialize_visual(owning_player) -> void:
	var color_name = "default"
	if owning_player.has_node("KinematicBody/CharacterModel"):
		var character_model_controller = owning_player.get_node("KinematicBody/CharacterModel")
		var color_scheme = character_model_controller.color_scheme
		color_name = color_scheme + "_main"
	# TODO: Check is necessary because server does not do any coloring, we should maybe 
	# make a client only version for this class
	if get_node("/root").has_node("ColorManager"):
		var color_manager = get_node("/root/ColorManager")
		color_manager.color_object_by_property(color_name, _mesh_instance.material_override, "albedo_color")
		color_manager.color_object_by_property(color_name, _mesh_instance.material_override, "emission")


func handle_hit(collider):
	Logger.debug("hit collider: %s" %[collider.get_class()] , "HitscanShot")
	var character = collider.get_parent()

	if character is GhostBase and not character == placed_by_body \
			and character.round_index < round_index:
		character.hit(_create_hit_data(character, HitData.HitType.WALL))

# TODO: this function is duplicate among all damaging actions, a shared interface would be nice maybe
func _create_hit_data(victim: CharacterBase, type) -> HitData:
	var hit_data = HitData.new()
	
	hit_data.type = type
	hit_data.position = global_transform.origin
	hit_data.rotation = global_transform.basis.get_euler().y
	
	hit_data.victim_team_id = victim.team_id
	hit_data.victim_round_index = victim.round_index
	hit_data.victim_timeline_index = victim.timeline_index
	
	hit_data.perpetrator_team_id = _owning_player.team_id
	hit_data.perpetrator_round_index = _owning_player.round_index
	hit_data.perpetrator_timeline_index = _owning_player.timeline_index
	
	return hit_data
