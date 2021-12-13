extends MeshInstance


var looking_at: Vector3


func _process(delta):
	look_at_from_position(global_transform.origin, looking_at, Vector3.UP)
