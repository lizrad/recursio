extends Spatial


var index_colors = {
	0: Color(0.0, 1.0, 0.0),
	1: Color(1.0, 1.0, 0.0),
	2: Color(0.0, 1.0, 1.0)
}


func set_curve(curve):
	$Path.curve = curve


func set_color_for_index(index):
	$Path/CSGPolygon.material_override.albedo_color = index_colors[index]
