extends RayCast

onready var _max_time = Constants.get_value("hitscan", "max_time")

var _bullet_range = Constants.get_value("hitscan", "range")
var _owning_player
var _first_frame := true


func _init() -> void:
	Logger.info("_init action", "HitscanShot")

func initialize(owning_player) -> void:
	Logger.info("initialize action", "HitscanShot")

	var color = Color(Constants.get_value("colors","neutral"))
	if owning_player.has_node("KinematicBody/CharacterModel"):
		var character_model_controller = owning_player.get_node("KinematicBody/CharacterModel")
		var color_scheme = character_model_controller.color_scheme
		color = Color(Constants.get_value("colors", color_scheme + "_primary_accent"))
	$Visualisation.material_override.albedo_color = color
	$HitPoint/FrontParticles.material_override.emission = color
	$HitPoint/BackParticles.material_override.emission = color

	cast_to = Vector3(0,0,-_bullet_range)
	_owning_player = owning_player
	add_exception(owning_player.get_body())

func _physics_process(delta):
	_max_time -= delta
	if _max_time <= 0:
		queue_free()
		Logger.info("freeing action..." , "HitscanShot")
		return

	if  _first_frame:
		_update_collision()
		_first_frame = false

func handle_hit(collider):
	var character = collider.get_parent()
	Logger.debug("hit collider: %s" %[collider.get_class()] , "HitscanShot")
	var collision_point = get_collision_point()
	var distance = (collision_point- global_transform.origin).length()
	$Visualisation.scale.y = distance*0.5
	$Visualisation.transform.origin.z = -distance*0.5

	if _first_frame:
		$HitPoint.global_transform.origin = collision_point
		$HitPoint/FrontParticles.emitting = true
		$HitPoint/BackParticles.emitting = true
	
	if character is CharacterBase:
		assert(character.has_method("hit"))
		character.hit(_owning_player)


func _update_collision():
	var collider = get_collider()
	if collider:
		var collision_point = get_collision_point()
		Logger.debug("Collision Point: "+str(collision_point), "HitscanShot")
		handle_hit(collider)
	else:
		$Visualisation.scale.y = _bullet_range*0.5
		$Visualisation.transform.origin.z = -_bullet_range*0.5
		
