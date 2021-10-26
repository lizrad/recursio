extends KinematicBody
class_name CharacterBase

signal hit

var ghost_index := -1
var round_index := -1

class MovementFrame:
	var position

var spawn_point := Vector3.ZERO
