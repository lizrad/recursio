extends StaticBody


var placed_by_body
var _current_health := 5
var round_index

func _init() -> void:
	Logger.info("_init action", "Wall")


func _ready():
	assert($KillGhostArea.connect("body_entered", self, "handle_hit") == OK)


func initialize(owning_player) -> void:
	initialize_visual(owning_player)
	placed_by_body = owning_player
	round_index = owning_player.round_index


func initialize_visual(owning_player) -> void:
	# TODO: define and use player color
	#$MeshInstance.material_override.albedo_color = Constants.character_colors[owning_player.id]
	print("owning player name: " + owning_player.name)
	print("owning player class: " + owning_player.get_class())
	if owning_player.has_node("Mesh_Body"):
		print("having mesh body")
		var mesh = owning_player.get_node("Mesh_Body")
		if mesh.material_override:
			$MeshInstance.material_override.albedo_color = mesh.material_override.albedo_color
		else:
			$MeshInstance.material_override.albedo_color = Color.red


func handle_hit(collider):
	Logger.debug("hit collider: %s" %[collider.get_class()] , "HitscanShot")
	
	if collider is Ghost and not collider == placed_by_body \
			and collider.round_index < round_index:
		collider.receive_hit()


func _hit_body(body) ->void:
	if body is Ghost and body != placed_by_body:
		Logger.info("body hit -> TODO: kill enemy contact/ghost/robot", "Wall")
		#body.daie()
