extends Node

class ObjectPropertyCoupling:
	var object: Object
	var property: String
	
	
	func _init(object: Object, property: String):
		self.object = weakref(object)
		self.property = property
	
	
	func apply_color(color: Color):
		object.get_ref().set(property, color)
	
	
	func equals(other_coupling) -> bool:
		return (object.get_ref() == other_coupling.object.get_ref() and property == other_coupling.property)

class ObjectMethodCoupling:
	var object: Object
	var method: String
	var args: Array


	func _init(object: Object, method: String, args: Array):
		self.object = weakref(object)
		self.method = method
		self.args = args


	func apply_color(color: Color):
		var all_args = args 
		all_args += [color]
		object.get_ref().callv(method, all_args)
	
	
	
	func equals(other_coupling) -> bool:
		return (object.get_ref() == other_coupling.object.get_ref() and method == other_coupling.method)


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


func _register_coupling(coupling, new_color_name: String):
	# TODO: this clean up step is pretty unperformant, with many loops and dictionary lookups, 
	# we might need to optimize this somehow or let the user take responsibility for
	# deregistering objects himself (trading ease of use for speed)
	for color_name in _colored_objects:
		_clean_up_color(color_name)
		# because we do this here it is ensured that every object only exists once, 
		# so after we found one we can early break the loop
		if(_delete_coupling(color_name, coupling)):
			break
	_colored_objects[new_color_name].append(coupling)
	var color = _get_color(new_color_name)
	coupling.apply_color(color)

# gets called when a user changes a color setting, and updates every relevant object on the fly
func color_changed(color_name: String):
	_clean_up_color(color_name)
	var color = _get_color(color_name)
	for i in range(0, _colored_objects[color_name].size()):
		var coupling = _colored_objects[color_name][i]
		coupling.apply_color(color)


# Remove every coupling where the object was already deleted
func _clean_up_color(color_name: String):
	var to_remove: Array = []
	for i in range(_colored_objects[color_name].size()-1, -1, -1):
		var coupling = _colored_objects[color_name][i]
		if coupling.object.get_ref() == null:
			_colored_objects[color_name].remove(i)


# Tries to delete the first occurence of a coupling that stores the same object
func _delete_coupling(color_name, coupling) -> bool:
	for i in range(_colored_objects[color_name].size()-1, -1, -1):
		var current_coupling = _colored_objects[color_name][i]
		if current_coupling.equals(coupling):
			_colored_objects[color_name].remove(i)
			return true
	return false
