extends Object
class_name Bitmask

var mask: int = 0

func _init(bits: int):
	mask = bits


func add(bit_index: int):
	mask = mask | bit_index


func remove(bit_index: int):
	mask = mask & ~bit_index
