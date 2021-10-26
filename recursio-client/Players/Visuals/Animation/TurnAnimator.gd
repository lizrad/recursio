extends BaseAnimator

onready var root_pivot = get_node("../RootPivot")
export var max_rotation := PI/3.0
export var max_velocity := 3.0
export var waver_speed := 8
export var waver_extent = PI/20.0

var _phase = 0
var _velocity = 0.0

func set_velocity(velocity):
	_velocity = min(velocity, max_velocity)
	
func get_keyframe(delta):
	_reset_keyframes()
	var ratio = abs(_velocity/max_velocity)
	var rotation = lerp(0,max_rotation,ratio) * sign(_velocity)
	_phase += delta*waver_speed
	if _velocity!=0:
		rotation+=sin(_phase)*waver_extent
	_keyframes[_root_pivot].basis =  _keyframes[_root_pivot].basis.rotated(Vector3(0,0,1),rotation)
	return _keyframes
