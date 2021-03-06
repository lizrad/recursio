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
# Only emit signal for client
func hit(hit_data: HitData):
	emit_signal("client_hit", hit_data)

func server_hit(hit_data: HitData):
	.hit(hit_data)
