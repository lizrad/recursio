extends Position3D

# Child node of the PLayer which serves as the camera target

export var distance_factor := 0.5

onready var _player = get_parent().get_parent()
onready var kb = get_parent()


func _process(_delta):
	# Add offset depending on velocity (counteract dash movement)
	translation = kb.global_transform.basis.get_rotation_quat().inverse() * _player.velocity * distance_factor
	# Add basic offset in eye direction
	translation.z -= 0.5
