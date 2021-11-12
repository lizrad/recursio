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
		character.hit()

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
