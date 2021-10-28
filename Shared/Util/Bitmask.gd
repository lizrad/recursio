extends Object
class_name Bitmask

var mask: int = 0

func _init(bits: int):
	set_bits(bits)


func add(bit_index: int):
	mask = mask | bit_index


func remove(bit_index: int):
	mask = mask & ~bit_index


func set_bits(bits: int):
	mask = bits
