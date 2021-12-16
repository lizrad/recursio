tool
extends SpotLight
onready var _tween = get_node("Tween")
onready var _toggle_time = Constants.get_value("visibility", "light_toggle_time")
onready var _spot_range = Constants.get_value("visibility", "spot_range")

func _ready():
	# The light energy entered here is the energy of the visual light. The light for the visibility
	# shader is multiplied by 10 in order to avoid artifacts.
	$SightLight.light_energy = light_energy
	light_energy *= 10
	$SightLight.spot_angle = spot_angle
	spot_range = 0
	$SightLight.spot_range = spot_range


# toggling lerps the light range between 0 and 12 for a smooth effect
func toggle(value):
	var start = spot_range
	var goal = _spot_range if value else 0
	_tween.remove_all()
	_tween.interpolate_property(self, "spot_range", start, goal, _toggle_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	_tween.interpolate_property($SightLight, "spot_range", start, goal, _toggle_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	_tween.start()
