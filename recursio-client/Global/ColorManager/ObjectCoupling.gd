extends Object
class_name ObjectCoupling


var _object


func _init(object) -> void: 
	# using weakref here because coupling have to become invalid 
	# if the object gets deleted 
	_object = weakref(object)


func is_valid() -> bool:
	return _object.get_ref() != null


func apply_color(_color: Color) -> void:
	assert(false) # this must be implemented in child classes


func equals(_other_coupling) -> bool:
	assert(false) # this must be implemented in child classes
	return false
