extends Position3D

# Child node of the PLayer which serves as the camera target

export var distance_factor := 0.5

onready var player = get_parent()


func _process(delta):
	# Add offset depending on velocity (counteract dash movement)
	translation = player.global_transform.basis.get_rotation_quat().inverse() * player.velocity * distance_factor
	# Add basic offset in eye direction
	translation.z -= 0.5
