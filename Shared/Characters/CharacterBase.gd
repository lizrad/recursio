extends Node
class_name CharacterBase

signal hit()
signal velocity_changed(velocity, front_vector, right_vector)
signal timeline_index_changed(timeline_index)
signal action_status_changed(action_type, status)

var player_id: int
# The team id defines which side the player starts on
var team_id: int = -1
# The timeline this character belongs to
var timeline_index: int = -1 setget set_timeline_index
# The spawn point of this character
var spawn_point: Vector3
# The round this character got created in
var round_index: int = -1

var last_triggers: Bitmask = Bitmask.new(0)


var position: Vector3 setget set_position, get_position
var rotation_y: float setget set_rotation_y, get_rotation_y
var velocity: Vector3 setget set_velocity

var _actions = {}


# Underlying kinematic body
onready var _kb: KinematicBody = get_node("KinematicBody")
onready var _collision_shape: CollisionShape = get_node("KinematicBody/CollisionShape")

var _action_manager

func character_base_init(action_manager) -> void:
	_action_manager = action_manager


func reset() -> void:
	self.velocity = Vector3.ZERO
	self.position = spawn_point
	self.rotation_y = 0
	self.timeline_index = 0


func move_to_spawn_point() -> void:
	self.position = spawn_point


# Returns the position of the underlying kinematic body
func get_position() -> Vector3:
	return _kb.transform.origin


# Returns the y-rotation of the underlying kinematic body
func get_rotation_y() -> float:
	return _kb.rotation.y;


# Sets the position of the underlying kinematic body
func set_position(new_position: Vector3) -> void:
	_kb.transform.origin = new_position


# Sets the y-rotation of the underlying kinematic body
func set_rotation_y(new_rotation_y: float) -> void:
	_kb.rotation.y = new_rotation_y


func set_velocity(new_velocity):
	emit_signal("velocity_changed", velocity, -_kb.transform.basis.z, _kb.transform.basis.x)
	velocity = new_velocity


func set_timeline_index(new_timeline_index: int):
	timeline_index = new_timeline_index
	emit_signal("timeline_index_changed", new_timeline_index)


func hit() -> void:
	emit_signal("hit")


func trigger_actions(buttons: int) -> void:
	# Go through buttons and trigger actions for them
	var number_of_bits = log(buttons) / log(2) + 1
	for bit_index in number_of_bits:
		# Triggers are represented as powers of two
		var trigger: int = pow(2, bit_index)
		var bit = buttons & trigger
		if not bit:
			continue

		var action = _get_action(trigger, timeline_index)
		var success = _action_manager.set_active(action, self, _kb, get_parent())
		if success:
			var type = _action_manager.get_action_type_for_trigger(trigger, timeline_index)
			emit_signal("action_status_changed", type, true)
			last_triggers.add(trigger)
		else:
			Logger.error("TODO: trigger can fail? or just not triggering because of cooldown?")


func get_action_manager():
	return _action_manager


# Always returns the same Action instance for the same trigger and timeline index. This preserves ammo count etc.
func _get_action(trigger, timeline_index):
	var id = timeline_index * 10 + trigger
	
	# Cache the action if it hasn't been cached yet
	if not _actions.has(id):
		_actions[id] = _action_manager.create_action_duplicate_for_trigger(trigger, timeline_index)

	return _actions[id]
