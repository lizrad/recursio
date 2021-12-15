extends ObjectCoupling
class_name ObjectPropertyCoupling


var property: String


func _init(object: Object, property: String).(object) -> void:
	self.property = property


func apply_color(color: Color) -> void:
	object.get_ref().set(property, color)


func equals(other_coupling) -> bool:
	if typeof(other_coupling) != typeof(self):
		return false
	return (object.get_ref() == other_coupling.object.get_ref() and property == other_coupling.property)
