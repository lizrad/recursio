extends Object

class_name InputData

var timestamp: int
var _data: RingBuffer

# Sets the size for the internal ring buffer
func _init(max_size: int)-> void:
	_data = RingBuffer.new(15)

func add(input_frame: InputFrame)-> void:
	_data.append(input_frame)


func get_elemet(index: int)-> InputFrame:
	return _data.get_element(index)

# Converts this class into an array
func to_array()-> Array:
	var array :=[]
	for input_frame in _data:
		array.append(input_frame)
	return array


# Creates an InputData from a given array
static func from_array(array: Array)-> InputData:
	var input_data: InputData
	input_data.timestamp = array[0]
	for i in range(1, array.size()):
		input_data.data.append(array[i])
	return input_data
