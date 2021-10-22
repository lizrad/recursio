tool
extends SpotLight


func _ready():
	$SightLight.light_energy = light_energy
	$SightLight.spot_angle = spot_angle
	$SightLight.spot_range = spot_range
