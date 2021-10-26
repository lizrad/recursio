extends Object

# Uses an array internally
# Removes the first (oldest) element when over max size
class_name RingBuffer

# Array containing the data
# Newest last, oldest first
var _data := []

# Max size of the ring buffer
var _max_size: int = 0
# Current size of the ring buffer
var _current_size: int = 0


# Sets the size for the internal array
func _init(max_size: int)-> void:
	_max_size = max_size


# Returns the current size of the ring buffer 
func size() -> int:
	return _current_size


# Returns the max size of the ring buffer 
func max_size() -> int:
	return _max_size


# Appends the given element
# If the ring buffer is full, removes first (oldest) element
func append(element) -> void:
	# If no space left, pop oldest
	if _current_size == _max_size:
		_data.pop_front()
		_current_size -= 1

	# Append element
	_data.append(element)
	_current_size += 1


# Returns the element at the given index
func get_element(index: int):
	return _data[index]

# Returns the last and thereby newest element from the ring buffer
func get_last():
	return _data[_current_size - 1]


# Returns the internal data-array
func get_data()-> Array:
	return _data
