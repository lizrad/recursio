extends Area

# TODO: combine attack common values
export var only_hit_one_body := true
var _damage := 10.0
var _bounce_strength := 250.0
var _attack_range := 1
var _attack_time := 0.1
var _owning_player
var _hit_something = false
var _continuously_damaging := false
var _damage_invincibility_time := 0
var _hit_bodies_invincibilty_tracker = {}


func initialize_visual() -> void:
	# TODO: define and use player color
	#$Visualization.get_surface_material(0).albedo_color = Constants.character_colors[owning_player.id]
	$Visualization.get_surface_material(0).albedo_color = Color.red

#func initialize(owning_player, attack_type) ->void:
func initialize(owning_player) -> void:
	#_damage = attack_type.damage
	#_bounce_strength = attack_type.bounce_strength
	#_continuously_damaging = attack_type.continuously_damaging
	#_damage_invincibility_time = attack_type.damage_invincibility_time
	_owning_player = owning_player
	initialize_visual()

func _process(delta):
	_attack_time -= delta
	if _attack_time <= 0:
		queue_free()
		return

	for i in _hit_bodies_invincibilty_tracker:
		_hit_bodies_invincibilty_tracker[i]-=delta
		_hit_bodies_invincibilty_tracker[i] = clamp(_hit_bodies_invincibilty_tracker[i],0,_damage_invincibility_time)


# TODO: Identical to the function in HitscanShot - consider using a shared parent class?
func _hit_body(collider):
	Logger.debug("hit collider: %s" %[collider.get_class()] , "Melee")
	
	if collider is CharacterBase:
		assert(collider.has_method("receive_hit"))
		if (not _hit_bodies_invincibilty_tracker.has(collider) or _hit_bodies_invincibilty_tracker[collider] <=0):
			_hit_bodies_invincibilty_tracker[collider]=_damage_invincibility_time
			collider.receive_hit()


func _physics_process(_delta):
	var bodies = get_overlapping_bodies()
	if bodies.size() == 0:
		return
	if not _continuously_damaging:
		if _hit_something:
			return
		var nearest_body
		var nearest_distance = INF
		for body in bodies:
			if _hit_something:
				return
			if not body is CharacterBase:
				continue
			if body == _owning_player:
				continue
			var distance = global_transform.origin.distance_to(body.global_transform.origin)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_body = body
		if nearest_body == null:
			return
		_hit_body(nearest_body)
	else:
		var other_player
		Logger.debug("hit bodies size: %d" %[bodies.size()], "Melee")
		for body in bodies:
			if not body is CharacterBase:
				continue
			if body == _owning_player:
				continue

			Logger.debug("hit body: %s" %[body.name], "Melee")
			# make sure we hit other player last
			if body is Player:
				Logger.debug("found other player", "Melee")
				other_player = body
				continue
			_hit_body(body)
		if other_player:
			Logger.debug("hit other player", "Melee")
			_hit_body(other_player)
