extends Spatial


export(NodePath) var target_node
onready var target = get_node(target_node)

export(float) var lerp_factor = 0.5
export(bool) var lock_y_rotation


func _physics_process(_delta):
	global_transform = global_transform.interpolate_with(target.global_transform, lerp_factor)
	
	if lock_y_rotation:
		rotation.y = 0.0
