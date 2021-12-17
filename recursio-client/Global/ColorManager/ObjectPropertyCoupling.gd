extends ObjectCoupling
class_name ObjectPropertyCoupling


var _property: String


# OVERRIDE #
func _init(object: Object, property: String).(object) -> void:
	self._property = property


# OVERRIDE #
func apply_color(color: Color) -> void:
	_object.get_ref().set(_property, color)


# OVERRIDE #
func equals(other_coupling) -> bool:
	if typeof(other_coupling) != typeof(self):
		return false
	return (_object.get_ref() == other_coupling._object.get_ref() and _property == other_coupling._property)
