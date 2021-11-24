extends Object

class_name InputData

const RING_BUFFER_SIZE: int = 32

var timestamp: int = -1
var _data: RingBuffer = RingBuffer.new(RING_BUFFER_SIZE)


# Adds the given InputFrame to the RingBuffer
func add(input_frame: InputFrame)-> void:
	_data.append(input_frame)


# Returns the InputFrame inside the RingBuffer at the given index
func get_elemet(index: int)-> InputFrame:
	return _data.get_element(index)


# Returns the newest element from the ring buffer
func get_newest():
	return _data.get_newest()


# Gets the next input frame (from new to old)
func get_next() -> InputFrame:
	return _data.get_next()


# Gets the previous input frame (from old to new)
func get_previous() -> InputFrame:
	return _data.get_previous()


# Resets the iteration index back to the newest element
func reset_iteration_index() -> void:
	_data.reset_iteration_index()


# Returns the size of the input data ringbuffer
func size() -> int:
	return _data.size()


# Returns the element closest to or earlier than the given time
func get_closest_or_earlier(time):
	for _i in range(_data.size() - 1):
		var element = _data.get_next()
		
		# Null element means everything afterwards is null as well
		if element == null:
			return null

		if element.timestamp <= time:
			return element


# Converts this class into an array
func to_array()-> Array:
	var array := [timestamp, _data.get_newest_index()]
	array.resize(2 + _data.size())
	
	for i in range(_data.size()):
		var frame: InputFrame = _data.get_element(i)
		if frame == null:
			break

		array[i + 2] = frame.to_array()
	
	return array


# Fills the object with the data from the given array
func from_array(data: Array)-> InputData:
	timestamp = data[0]
	_data._newest_index = data[1]
	_data.reset_iteration_index()
	
	for i in range(_data.size()):
		if data[i + 2] == null:
			break

		var frame: InputFrame = InputFrame.new().from_array(data[i + 2])
		_data._data[i] = frame
	
	return self


func debug_print()-> void:
	for i in _data.size():
		if _data.get_element(i) != null:
			print(_data.get_element(i).to_array())
