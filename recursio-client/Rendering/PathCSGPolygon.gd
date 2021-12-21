extends CSGPolygon


var color setget set_color


# Adapter to make `ColorManager.color_object_by_property` integrate neatly
func set_color(new_color: Color):
	material_override.set_shader_param("color", new_color)
