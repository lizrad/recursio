extends Node

# This class is necessary because we plan on adding the capability to use settings
# during the game. This means we have to be able to change colors on the fly, which
# makes it necessary to track which object were colored how. This is what this class
# does. It then gets notified by the ColorSetting class if settings were changed.

var header: String = "colors"
var _colored_objects: Dictionary = {}


func _ready() -> void:
	# setup object lists
	var colors = UserSettings.get_all_settings_for_header(header)
	for color_name in colors:
		_colored_objects[color_name] = []


func _get_color(color_name: String) -> Color:
	return Color(UserSettings.get_setting(header, color_name))

# uses the passed property to color an object
func color_object_by_property(color_name: String, object: Object, property: String) -> void:
	assert(is_instance_valid(object))
	assert(_colored_objects.has(color_name))
	var coupling :ObjectPropertyCoupling = ObjectPropertyCoupling.new(object, property)
	_register_coupling(coupling, color_name)

# uses the passed method to color an object, probably only necessary when using the set_shader_param functions
# this expect the color to be the last argument in the called method
func color_object_by_method(color_name: String, object: Object, method: String, additional_method_args: Array) -> void:
	assert(is_instance_valid(object))
	assert(_colored_objects.has(color_name))
	var coupling :ObjectMethodCoupling = ObjectMethodCoupling.new(object, method, additional_method_args)
	_register_coupling(coupling, color_name)


# stores an object in the internal dictionary so we can color it on the fly when settings change
func _register_coupling(coupling, new_color_name: String) -> void:
	# TODO: this clean up step is pretty unperformant, with many loops and dictionary lookups, 
	# we might need to optimize this somehow or let the user take responsibility for
	# deregistering objects himself (trading ease of use for speed) but for now it seems fast enough
	# during testing
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
func color_changed(color_name: String) -> void:
	_clean_up_color(color_name)
	var color = _get_color(color_name)
	for i in range(0, _colored_objects[color_name].size()):
		var coupling = _colored_objects[color_name][i]
		coupling.apply_color(color)


# Remove every coupling where the object was already deleted
func _clean_up_color(color_name: String) -> void:
	for i in range(_colored_objects[color_name].size()-1, -1, -1):
		var coupling = _colored_objects[color_name][i]
		if not coupling.is_valid():
			_colored_objects[color_name][i].free()
			_colored_objects[color_name].remove(i)


# Tries to delete the first occurence of a coupling that stores the same object
func _delete_coupling(color_name, coupling) -> bool:
	for i in range(_colored_objects[color_name].size()-1, -1, -1):
		var current_coupling = _colored_objects[color_name][i]
		if current_coupling.equals(coupling):
			_colored_objects[color_name][i].free()
			_colored_objects[color_name].remove(i)
			return true
	return false
