extends ObjectCoupling
class_name ObjectMethodCoupling


var method: String
var args: Array


func _init(object: Object, method: String, args: Array).(object) -> void:
	self.method = method
	self.args = args


func apply_color(color: Color) -> void:
	var all_args = args 
	all_args += [color]
	object.get_ref().callv(method, all_args)


func equals(other_coupling) -> bool:
	if typeof(other_coupling) != typeof(self):
		return false
	return (object.get_ref() == other_coupling.object.get_ref() and method == other_coupling.method)
