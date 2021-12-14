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
var _colored_objects: Dictionary = {}


func _ready():
	var colors = UserSettings.get_all_settings_for_header(_header)
	for color_name in colors:
		_colored_objects[color_name] = []


func _get_color(color_name: String) -> Color:
	return Color(UserSettings.get_setting(_header, color_name))


func color_object_by_property(color_name: String, object: Object, property: String):
	assert(is_instance_valid(object))
	assert(_colored_objects.has(color_name))
	var coupling :ObjectPropertyCoupling = ObjectPropertyCoupling.new(object, property)
	_register_coupling(coupling, color_name)


# this expect the color to be the last argument in the called method
func color_object_by_method(color_name: String, object: Object, method: String, additional_method_args: Array):
	assert(is_instance_valid(object))
	assert(_colored_objects.has(color_name))
	var coupling :ObjectMethodCoupling = ObjectMethodCoupling.new(object, method, additional_method_args)
	_register_coupling(coupling, color_name)

func _register_coupling(coupling, color_name: String):
	#TODO: check if coupling already exists, if so delete the older one
	print("Registering "+ str(coupling.object)+ " to color "+color_name)
	var color = _get_color(color_name)
	coupling.apply_color(color)
	_colored_objects[color_name].append(coupling)

func color_changed(color_name: String):
	var color = _get_color(color_name)
	var to_remove: Array = []
	for i in range(0, _colored_objects[color_name].size()):
		var coupling = _colored_objects[color_name][i]
		print("Color changed for "+str(coupling.object)+ " with color "+color_name)
		if is_instance_valid(coupling.object):
			coupling.apply_color(color)
		else:
			to_remove.append(i)
	# Removing objects that have become invalid
	# TODO: This does not work. If i play the tutorial after 
	# I already played online and change a color during the tutorial nothing 
	# gets deleted even though object from online play have been stored 
	# in the array before. I thought they would automatically become invalid?
	for i in to_remove:
		_colored_objects[color_name].remove(i)
