extends PlayerBase
class_name Enemy

var last_position: Vector3
var server_position: Vector3
var last_velocity: Vector3
var server_velocity: Vector3

var server_acceleration: Vector3


func enemy_init(action_manager: ActionManager) -> void:
	.player_base_init(action_manager)


#TODO: Should be extrapolated input and called twice as often as we get info from server
func apply_input(movement: Vector3, rotation: Vector3, buttons: int) -> void:
	.apply_input(movement, rotation, buttons)
