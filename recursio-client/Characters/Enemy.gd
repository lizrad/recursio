extends PlayerBase
class_name Enemy

signal client_hit()

var last_position: Vector3
var server_position: Vector3
var last_velocity: Vector3
var server_velocity: Vector3

var server_acceleration: Vector3


func enemy_init(action_manager: ActionManager) -> void:
	.player_base_init(action_manager)


# OVERRIDE #
func hit(_perpetrator):
	emit_signal("client_hit")

func server_hit(perpetrator):
	.hit(perpetrator)
