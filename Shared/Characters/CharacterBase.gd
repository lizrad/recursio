extends Node
class_name CharacterBase

signal hit()


# The timeline this character belongs to
var timeline_index: int = -1
# The spawn point of this character
var spawn_point: Vector3 = Vector3.ZERO

# Property for quick access
var position: Vector3 = Vector3.ZERO setget set_position, get_position
# Property for quick access
var rotation_y: float = 0.0 setget set_rotation_y, get_rotation_y


# Underlying kinematic body
onready var _kb: KinematicBody = get_node("KinematicBody")

var _action_manager: ActionManager

func _init(action_manager: ActionManager):
	_action_manager = action_manager


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








