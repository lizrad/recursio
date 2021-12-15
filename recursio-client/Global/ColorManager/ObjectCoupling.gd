extends Object
class_name ObjectCoupling


var object


func _init(object) -> void: 
	self.object = weakref(object)


func apply_color(_color: Color) -> void:
	assert(false) # this must be implemented in child classes


func equals(_other_coupling) -> bool:
	assert(false) # this must be implemented in child classes
	return false
