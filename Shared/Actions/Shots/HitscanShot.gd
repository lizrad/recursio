extends RayCast

onready var _max_time = Constants.get_value("hitscan", "max_time")
onready var _bullet_range = Constants.get_value("hitscan", "range")
onready var _camera_shake_amount = Constants.get_value("vfx","shoot_camera_shake_amount")
onready var _camera_shake_speed  = Constants.get_value("vfx","shoot_camera_shake_speed")
onready var _camera_shake_duration  = Constants.get_value("vfx","shoot_camera_shake_duration")

var _owning_player

var _current_animated_range := 0.001
var _animated_range_increase_velocity := 100.0

var _current_range := 0.0


func _init() -> void:
	Logger.info("_init action", "HitscanShot")


func initialize(owning_player) -> void:
	Logger.info("initialize action", "HitscanShot")

	var color_name = "neutral"
	if owning_player.has_node("KinematicBody/CharacterModel"):
		var character_model_controller = owning_player.get_node("KinematicBody/CharacterModel")
		var color_scheme = character_model_controller.color_scheme
		color_name = color_scheme + "_main"
	
	# TODO: Check is necessary because server does not do any coloring, we should maybe 
	# make a client only version for this class
	if get_node("/root").has_node("ColorManager"):
		var color_manager = get_node("/root/ColorManager")
		color_manager.color_object_by_property(color_name, $Visualisation.material_override, "albedo_color")
		color_manager.color_object_by_property(color_name, $Visualisation.material_override, "emission")
		color_manager.color_object_by_property(color_name, $HitPoint/FrontParticles.material_override, "emission")
		color_manager.color_object_by_property(color_name, $HitPoint/BackParticles.material_override, "emission")

	cast_to = Vector3(0,0,-_bullet_range)
	_owning_player = owning_player
	add_exception(owning_player.get_body())
	
	# Trigger post processing effects if this is an active player
	if _owning_player is PlayerBase:
		PostProcess.animate_property("chromatic_ab_strength", 0.5, 0, _max_time)
		PostProcess.shake_camera(_camera_shake_amount, _camera_shake_speed, _camera_shake_duration)


func _physics_process(delta):
	_max_time -= delta
	if _max_time <= 0:
		queue_free()
		Logger.info("freeing action..." , "HitscanShot")
		return

	_update_collision()
	
	_current_animated_range += _animated_range_increase_velocity * delta
	_update_visual_range()


func handle_hit(collider):
	var character = collider.get_parent()
	Logger.debug("hit collider: %s" %[collider.get_class()] , "HitscanShot")
	var collision_point = get_collision_point()
	var distance = (collision_point- global_transform.origin).length()
	_current_range = distance

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
	$Visualisation.scale.x = 0.01 / (_current_animated_range * 0.05)
	$Visualisation.transform.origin.z = -animated_range * 0.5
