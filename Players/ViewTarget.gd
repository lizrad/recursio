extends Position3D

# Child node of the PLayer which serves as the camera target

export var distance_factor := 0.5

onready var player = get_parent()


func _process(delta):
	translation.z = -player.velocity.length() * distance_factor
