extends KinematicBody
class_name CharacterBase

onready var Server = get_node("/root/Server")
var game_id := -1
var player_id := -1
var ghost_index := -1
var round_index := -1

#just putting this here for now as CharacterBase is not shared yet but ghost sets this value
#TODO: use var from client CharacterBase once we use a shared script
var velocity  := Vector3.ZERO
var spawn_point := Vector3.ZERO

signal hit

func set_action_status(action_type, status):
	#just putting this here for now as CharacterBase is not shared yet but ghost is and calls this function
	#TODO: use function from client CharacterBase once we use a shared script
	pass
