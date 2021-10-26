extends Object

class_name InputData

const RING_BUFFER_SIZE: int = 15

var timestamp: int
var _data: RingBuffer = RingBuffer.new(RING_BUFFER_SIZE)

# Fills the object with the data from the given array
func from_array(data: Array)-> InputData:
	timestamp = data[0]
	for i in range(1, data.size()):
		_data.append(InputFrame.new().from_array(data[i]))
	return self


# Adds the given InputFrame to the RingBuffer
func add(input_frame: InputFrame)-> void:
	_data.append(input_frame)


# Returns the InputFrame inside the RingBuffer at the given index
func get_elemet(index: int)-> InputFrame:
	return _data.get_element(index)


# Returns the last and thereby newest element from the ring buffer
func get_last():
	return _data.get_last()


# Converts this class into an array
func to_array()-> Array:
	var array := [timestamp]
	for i in range(_data.size()):
		array.append(_data.get_element(i).to_array())
	return array

func debug_print()-> void:
	for i in _data.size():
		print(_data.get_element(i).to_array())
