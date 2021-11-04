extends StaticBody


var placed_by_body
var round_index

func _init() -> void:
	Logger.info("_init action", "Wall")


func _ready():
	$KillGhostArea.connect("body_entered", self, "handle_hit") 


func initialize(owning_player) -> void:
	initialize_visual(owning_player)
	placed_by_body = owning_player
	owning_player.wall_spawned(self)
	round_index = owning_player.round_index


func initialize_visual(owning_player) -> void:
	var color = Color(Constants.get_value("colors","neutral"))
	if owning_player.has_node("KinematicBody/CharacterModel"):
		var character_model_controller = owning_player.get_node("KinematicBody/CharacterModel")
		var color_scheme = character_model_controller.color_scheme
		color = Color(Constants.get_value("colors",color_scheme+"_secondary_accent"))
	$MeshInstance.material_override.albedo_color = color
	$MeshInstance.material_override.emission = color


func handle_hit(collider):
	Logger.debug("hit collider: %s" %[collider.get_class()] , "HitscanShot")
	var character = collider.get_parent()
	
	if character is GhostBase and not character == placed_by_body \
			and character.round_index < round_index:
		character.hit()
