extends Spatial


var selected = false setget _set_selected
var index = 0 setget _set_index


func set_curve(curve: Curve3D):
	$PathMiddle.global_transform.origin = curve.get_point_position(int(floor(curve.get_point_count()*0.5)))
	$Path.curve = curve


func delete_curve():
	$Path.curve = Curve3D.new()

func _set_selected(new_selected:bool):
	selected = new_selected
	change_color()


func _set_index(new_index:int):
	index = new_index
	change_color()


func change_color():
	var color_name = "highlight" if selected else "default"
	transform.origin.y = 0.5 if selected else 0.0 # Make sure this path is on top
	ColorManager.color_object_by_property(color_name, $Path/PathCSGPolygon, "color")
