extends ObjectCoupling
class_name ObjectMethodCoupling


var _method: String
var _args: Array

# OVERRIDE #
func _init(object: Object, method: String, args: Array).(object) -> void:
	_method = method
	_args = args


# OVERRIDE #
func apply_color(color: Color) -> void:
	var all_args = _args 
	all_args += [color]
	_object.get_ref().callv(_method, all_args)


# OVERRIDE #
func equals(other_coupling) -> bool:
	if typeof(other_coupling) != typeof(self):
		return false
	return (_object.get_ref() == other_coupling._object.get_ref() and _method == other_coupling._method)
