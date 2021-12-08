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
func hit(perpetrator):
	pass

func server_hit():
	#TODO: using null here because we dont record deaths on the client anyway but this is kinda wack
	.hit(null)
