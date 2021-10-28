extends PlayerBase
class_name Enemy

#TODO: Should be extrapolated input and called twice as often as we get info from server
func apply_input(movement: Vector3, rotation: Vector3, buttons: int) -> void:
	.apply_input(movement, rotation, buttons)
