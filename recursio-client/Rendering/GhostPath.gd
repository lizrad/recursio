extends Spatial


var selected = false setget _set_selected
var index = 0 setget _set_index


func set_curve(curve):
	$Path.curve = curve


func _set_selected(new_selected:bool):
	selected = new_selected
	change_color()


func _set_index(new_index:int):
	index = new_index
	change_color()


func change_color():
	var color_name = "selected" if selected else "unselected"
	transform.origin.y = 0.5 if selected else 0.0 # Make sure this path is on top
	ColorManager.color_object_by_property(color_name, $Path/PathCSGPolygon, "color")
