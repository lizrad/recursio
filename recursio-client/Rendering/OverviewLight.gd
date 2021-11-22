extends OmniLight


export var max_radius := 50.0
export var radius_diff := 7.0
export var radius_grow_speed := 50.0

var enabled = false


func _physics_process(delta):
	if enabled:
		omni_range += radius_grow_speed * delta
		$Subtractive.omni_range = omni_range - radius_diff
		visible = true
		
		if omni_range > max_radius:
			omni_range = 0
			$Subtractive.omni_range = 0
	else:
		omni_range = 0
		$Subtractive.omni_range = 0
		visible = false
