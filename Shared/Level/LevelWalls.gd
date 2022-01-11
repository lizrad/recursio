extends MeshInstance

func _ready() -> void:
	# TODO: Check is necessary because server does not do any coloring, we should maybe 
	# make a client only version for this class
	if get_node("/root").has_node("ColorManager"):
		var color_manager = get_node("/root/ColorManager")
		color_manager.color_object_by_property("walls", material_override, "albedo_color")
