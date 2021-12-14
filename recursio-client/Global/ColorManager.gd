extends Node

class ObjectPropertyCoupling:
	var object: Object
	var property: String
	
	
	func _init(object: Object, property: String):
		self.object = object
		self.property = property
	
	
	func apply_color(color: Color):
		object.set(property, color)


class ObjectMethodCoupling:
	var object: Object
	var method: String
	var args: Array


	func _init(object: Object, method: String, args: Array):
		self.object = object
		self.method = method
		self.args = args


	func apply_color(color: Color):
		var all_args = args 
		all_args += [color]
		object.callv(method, all_args)


var _header: String = "colors"

func _get_color(color_name: String) -> Color:
	return Color(UserSettings.get_setting(_header, color_name))


func color_object_by_property(color_name: String, object: Object, property: String):
	assert(is_instance_valid(object))
	var coupling :ObjectPropertyCoupling = ObjectPropertyCoupling.new(object, property)
	var color = _get_color(color_name)
	coupling.apply_color(color)
	


# this expect the color to be the last argument in the called method
func color_object_by_method(color_name: String, object: Object, method: String, additional_method_args: Array):
	assert(is_instance_valid(object))
	var coupling :ObjectMethodCoupling = ObjectMethodCoupling.new(object, method, additional_method_args)
	var color = _get_color(color_name)
	coupling.apply_color(color)
