extends Node
class_name CharacterBase

signal hit()
signal action_status_changed(action_type, status)
signal velocity_changed(velocity, front_vector, right_vector)
signal timeline_index_changed(ghost_index)

# The team id defines which side the player starts on
var team_id: int = -1
# The timeline this character belongs to
var timeline_index: int = -1 setget set_timeline_index
# The spawn point of this character
var spawn_point: Vector3


var position: Vector3 setget set_position, get_position
var rotation_y: float setget set_rotation_y, get_rotation_y
var velocity: Vector3 setget set_velocity


# Underlying kinematic body
onready var _kb: KinematicBody = get_node("KinematicBody")

var _action_manager: ActionManager

func _init(action_manager: ActionManager):
	_action_manager = action_manager


func reset() -> void:
	self.velocity = Vector3.ZERO
	self.position = Vector3.ZERO
	self.rotation_y = 0


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


func set_timeline_index(new_timeline_index):
	emit_signal("timeline_index_changed", new_timeline_index)
	timeline_index = new_timeline_index


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
		
		Logger.info("Handling action of type " + str(trigger), "actions")
		var action = _action_manager.get_action_for_trigger(trigger, timeline_index)
		_action_manager.set_active(action, true, _kb, get_parent())


func get_action_manager() -> ActionManager:
	return _action_manager








