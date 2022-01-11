extends Reference

# Uses an array internally
# Removes the first (oldest) element when over max size
class_name RingBuffer

# Max size of the ring buffer
var _size: int = 0

# The index of the next element in the ringbuffer to be replaced
var _newest_index: int = -1

# Used for iterating through 
var _iteration_index: int = 0


# Array containing the data
# Newest last, oldest first
var _data := []


# Sets the size for the internal array
func _init(size: int) -> void:
	# Check for power of two
	assert(size && !(size & (size - 1)))
	_size = size
	_data.resize(size)


# Returns the size of the ring buffer 
func size() -> int:
	return _size


# Appends the given element
# If the ring buffer is full, replaces oldest element
func append(element) -> void:
	# Loop back
	_newest_index = (_newest_index + 1) & ~_size
	_data[_newest_index] = element
	_iteration_index = _newest_index


# Returns the element at the given index
func get_element(index: int):
	return _data[index]


# Returns the newest element in the ringbuffer
func get_newest():
	return _data[_newest_index]


# Goes through all elements from newest to oldest
func get_next():
	var temp_index = _iteration_index
	_iteration_index -= 1
	_iteration_index = _size - 1 if _iteration_index < 0 else _iteration_index
	return _data[temp_index]


# Goes through all elements from oldest to newest
func get_previous():
	_iteration_index += 1
	_iteration_index = 0 if _iteration_index == _size else _iteration_index
	return _data[_iteration_index]


# Moves the iterating index back to the newest element
func reset_iteration_index():
	_iteration_index = _newest_index


# Returns the index of the newest element
func get_newest_index():
	return _newest_index


# Returns the internal data-array
func get_data() -> Array:
	return _data
