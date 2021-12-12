extends StaticBody

export var animation_time:= 3.0

onready var _mesh_pivot = get_node("MeshPivot")
onready var _mesh_instance = get_node("MeshPivot/MeshInstance")
var _time_since_spawn := 0.0
var placed_by_body
var round_index
var _owning_player

func _init() -> void:
	Logger.info("_init action", "Wall")

#adapted from: https://easings.net/#easeOutElastic
func ease_out_elastic(x: float, wobble: float) -> float:
	var c4 = (2.0 * PI) / 3.0
	return 0.0 if x == 0 else (1.0 if x == 1 else  pow(2.0, -10.0 * x) * sin((x * wobble - 0.75) * c4) + 1.0);

func _process(delta):
	_time_since_spawn += delta
	var ratio = min(1, _time_since_spawn/animation_time)
	var remapped_ratio = ease_out_elastic(ratio,15.0)
	_mesh_pivot.scale = Vector3(1, remapped_ratio, 1)
	
	if _time_since_spawn >= animation_time:
		set_physics_process(false)

func _ready():
	var _error = $KillGhostArea.connect("body_entered", self, "handle_hit") 


func initialize(owning_player) -> void:
	initialize_visual(owning_player)
	placed_by_body = owning_player
	owning_player.wall_spawned(self)
	_owning_player = owning_player
	round_index = owning_player.round_index


func initialize_visual(owning_player) -> void:
	var color = Color(Constants.get_value("colors", "neutral"))
	if owning_player.has_node("KinematicBody/CharacterModel"):
		var character_model_controller = owning_player.get_node("KinematicBody/CharacterModel")
		var color_scheme = character_model_controller.color_scheme
		color = Color(Constants.get_value("colors", color_scheme + "_main"))
	_mesh_instance.material_override.albedo_color = color
	_mesh_instance.material_override.emission = color


func handle_hit(collider):
	Logger.debug("hit collider: %s" %[collider.get_class()] , "HitscanShot")
	var character = collider.get_parent()

	if character is GhostBase and not character == placed_by_body \
			and character.round_index < round_index:
		character.hit(_owning_player)
