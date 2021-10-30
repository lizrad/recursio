extends RayCast

# TODO: combine attack common values
var _continuosly_damaging := false
var _damage_invincibility_time := 1.1
var _bullet_range := 5
var _attack_time := 0.5
var _owning_player
var _damage := 10.0
var _bounce_strength := 50.0
var _visual := false
var _first_frame := true
var _hit_bodies_invincibilty_tracker = {}
var _attack_type_type

# TODO: use LineRenderer to visualize

func _init() -> void:
	Logger.info("_init action", "HitscanShot")

#func initialize(owning_player, attack_type) ->void:
func initialize(owning_player) -> void:
	Logger.info("initialize action", "HitscanShot")
	_visual = true
	#_damage = attack_type.damage
	#_bounce_strength = attack_type.bounce_strength
	#_bullet_range = attack_type.attack_range
	#_continuosly_damaging = attack_type.continuously_damaging
	#_damage_invincibility_time = attack_type.damage_invincibility_time
	cast_to = Vector3(0,0,-_bullet_range)
	#_attack_time = attack_type.attack_time
	_owning_player = owning_player
	add_exception(owning_player)
	#_attack_type_type = attack_type.attack_type_type

	#$LineRenderer.points = []
	#$LineRenderer.points.append(Vector3.ZERO)
	#$LineRenderer.points.append(Vector3.ZERO)
	#$LineRenderer.material_override.albedo_color = Constants.character_colors[_owning_player.id]
	_update_collision()
	
func _physics_process(delta):

	_attack_time -= delta
	if _attack_time <= 0:
		queue_free()
		Logger.info("freeing action..." , "HitscanShot")
		return

	for i in _hit_bodies_invincibilty_tracker.keys():
		_hit_bodies_invincibilty_tracker[i] -= delta
		_hit_bodies_invincibilty_tracker[i] = clamp(_hit_bodies_invincibilty_tracker[i],0,_damage_invincibility_time)

	if _visual or (not _first_frame and not _continuosly_damaging):
		var collider = get_collider()
		if collider:
			handle_hit(collider)
	#		var hit_point = to_local(get_collision_point())
	#		$LineRenderer.points[1] = hit_point if hit_point.length()<_bullet_range else Vector3(0,0,-_bullet_range)
	#	else:
	#		$LineRenderer.points[1] = Vector3(0,0,-_bullet_range)
	#	$LineRenderer.material_override.albedo_color = Constants.character_colors[_owning_player.id]
	elif _continuosly_damaging or _first_frame:
		_first_frame = false
		_update_collision()


func handle_hit(collider):
	Logger.debug("hit collider: %s" %[collider.get_class()] , "HitscanShot")
	var collision_point = get_collision_point()
	var distance = (collision_point- global_transform.origin).length()
	$Visualisation.scale.y = distance*0.5
	$Visualisation.transform.origin.z = -distance*0.5
	
	if _first_frame:
		$HitPoint.global_transform.origin = collision_point
		$HitPoint/FrontParticles.emitting = true
		$HitPoint/BackParticles.emitting = true
		
		_first_frame = false
	
	if collider is GhostBase:
		assert(collider.has_method("hit"))
		if (not _hit_bodies_invincibilty_tracker.has(collider) or _hit_bodies_invincibilty_tracker[collider] <=0):
			_hit_bodies_invincibilty_tracker[collider]=_damage_invincibility_time
			collider.hit()


func _update_collision():
	$Visualisation.scale.y = _bullet_range*0.5
	$Visualisation.transform.origin.z = -_bullet_range*0.5
	var collider = get_collider()
	if collider:
		var collision_point = get_collision_point()
		Logger.debug("Collision Point: "+str(collision_point), "HitscanShot")
		handle_hit(collider)
