extends Area

onready var _max_time = Constants.get_value("melee", "max_time")

var _owning_player
var _hit_something = false

func initialize(owning_player) -> void:
	Logger.debug("initialize", "Melee")
	_owning_player = owning_player

func _process(delta):
	_max_time -= delta
	if _max_time <= 0:
		queue_free()
		return

func _hit_body(collider):
	Logger.debug("hit collider: %s" %[collider.get_class()] , "Melee")
	var character = collider.get_parent()
	_hit_something = true
	if character is CharacterBase:
		assert(character.has_method("hit"))
		character.hit(_create_hit_data(character, HitData.HitType.MELEE))

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


func _physics_process(_delta):
	if _hit_something:
		return

	var bodies = get_overlapping_bodies()
	if bodies.size() == 0:
		return

	Logger.debug("melee hit " + str(bodies.size()) + (" bodies." if bodies.size() != 1 else " body."), "Melee")

	var nearest_body = null
	var nearest_distance = INF
	for body in bodies:
		if not body.get_parent() is CharacterBase:
			continue
		if body == _owning_player.get_body():
			continue

		var distance = global_transform.origin.distance_to(body.global_transform.origin)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_body = body
	if nearest_body == null:
		return

	_hit_body(nearest_body)
