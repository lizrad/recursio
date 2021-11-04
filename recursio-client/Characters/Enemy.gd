extends PlayerBase
class_name Enemy

var last_position: Vector3
var server_position: Vector3
var last_velocity: Vector3
var server_velocity: Vector3

var server_acceleration: Vector3


func enemy_init(action_manager: ActionManager) -> void:
	.player_base_init(action_manager)


# OVERRIDE #
func hit():
	pass

func server_hit():
	.hit()
