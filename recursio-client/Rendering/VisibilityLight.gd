tool
extends SpotLight
var _currently_toggling = false
var _toggle_goal = -1
var _toggle_start = -1
var _time_since_toggle_start = -1
onready var _toggle_time = Constants.get_value("visibility", "light_toggle_time")
onready var _spot_range = Constants.get_value("visibility", "spot_range")

func _ready():
	$SightLight.light_energy = light_energy
	$SightLight.spot_angle = spot_angle
	spot_range = 0
	$SightLight.spot_range = spot_range

func _process(delta):
	if _currently_toggling:
		_time_since_toggle_start += delta
		var ratio = _time_since_toggle_start/_toggle_time
		if _time_since_toggle_start >_toggle_time:
			_currently_toggling = false
			ratio = 1
		spot_range = lerp(_toggle_start,_toggle_goal, ratio)
		$SightLight.spot_range = spot_range
	

# toggling lerps the light range between 0 and 12 for a smooth effect
func toggle(value):
	_time_since_toggle_start = 0
	_currently_toggling = true
	if value:
		_toggle_goal = _spot_range
		_toggle_start = spot_range
	else:
		_toggle_goal = 0
		_toggle_start = spot_range
