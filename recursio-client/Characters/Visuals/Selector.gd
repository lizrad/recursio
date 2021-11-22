extends MeshInstance

export var speed := 5.0
export var min_positon := Vector3(0,0,0)
export var max_positon := Vector3(3,0,0)

var _timer := 0.0
var _active := false

func activate():
	show()
	_timer = 0.0
	_active = true

func deactivate():
	hide()
	_active = false

func _process(delta):
	if _active:
		_timer+= delta
		var t = sin(speed*_timer)
		transform.origin = lerp(min_positon, max_positon, t)
