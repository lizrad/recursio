extends Object
class_name DeadZones

# Applies dead zones on an input-vector
# Also normalizes the input, if necessary
static func apply_2D(input: Vector2, inner: float, outer: float):
	var x_axis = apply_1D(input.x, inner, outer)
	var y_axis = apply_1D(input.y, inner, outer)
	var result = Vector2(x_axis, y_axis)
	# Only normalize if bigger than 1
	return result.normalized() if result.length() > 1.0 else result


# Applies dead zones on one axis.
static func apply_1D(value: float, inner: float, outer: float):
	# Use absolute for calculation, then map back to actual sign
	var absolute = abs(value)
	# inverse_lerp returns t [0,1] which defines the interpolating value for c, between a and b
	return inverse_lerp(inner, outer, absolute) * sign(value)
