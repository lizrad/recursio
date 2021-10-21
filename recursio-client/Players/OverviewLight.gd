extends SpotLight


export var speed := 40
export var max_height := 60

var enabled = true


func _physics_process(delta):
	if enabled:
		transform.origin.y += delta * speed
		if transform.origin.y >= max_height:
			transform.origin.y = 0
		visible = true
	else:
		transform.origin.y = 0
		visible = false
