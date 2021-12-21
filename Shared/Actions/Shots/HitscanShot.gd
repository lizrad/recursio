extends RayCast

onready var _max_time = Constants.get_value("hitscan", "max_time")
onready var _bullet_range = Constants.get_value("hitscan", "range")

var _owning_player
var _first_frame := true

var _current_animated_range := 0.0
var _animated_range_increase_velocity := 80.0

var _current_range := 0.0


func _init() -> void:
	Logger.info("_init action", "HitscanShot")


func initialize(owning_player) -> void:
	Logger.info("initialize action", "HitscanShot")

	var color_name = "neutral"
	if owning_player.has_node("KinematicBody/CharacterModel"):
		var character_model_controller = owning_player.get_node("KinematicBody/CharacterModel")
		var color_scheme = character_model_controller.color_scheme
		color_name = color_scheme + "_primary_accent"
	
	# TODO: Check is necessary because server does not do any coloring, we should maybe 
	# make a client only version for this class
	if get_node("/root").has_node("ColorManager"):
		var color_manager = get_node("/root/ColorManager")
		color_manager.color_object_by_property(color_name, $Visualisation.material_override, "albedo_color")
		color_manager.color_object_by_property(color_name, $HitPoint/FrontParticles.material_override, "emission")
		color_manager.color_object_by_property(color_name, $HitPoint/BackParticles.material_override, "emission")

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
	
	_current_animated_range += _animated_range_increase_velocity * delta
	_update_visual_range()


func handle_hit(collider):
	var character = collider.get_parent()
	Logger.debug("hit collider: %s" %[collider.get_class()] , "HitscanShot")
	var collision_point = get_collision_point()
	var distance = (collision_point- global_transform.origin).length()
	_current_range = distance

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
		Logger.debug("Collision Point: " + str(collision_point), "HitscanShot")
		handle_hit(collider)
	else:
		_current_range = _bullet_range


func _update_visual_range():
	var animated_range = min(_current_range, _current_animated_range)
	$Visualisation.scale.y = animated_range * 0.5
	$Visualisation.scale.x = 0.025 + 0.01 / (_current_animated_range * 0.05)
	$Visualisation.transform.origin.z = -animated_range * 0.5
