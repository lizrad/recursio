extends Object

class_name StaticInput

static func calculate_acceleration(movement_vector, rotation_vector)-> float:
	var base = Constants.get_value("movement", "scale_to_view_base")
	var factor = Constants.get_value("movement", "scale_to_view_factor")
	var move_acceleration = Constants.get_value("movement", "acceleration")
	
	var direction_scale = base + movement_vector.dot(rotation_vector) / factor
	
	return movement_vector * move_acceleration * direction_scale
