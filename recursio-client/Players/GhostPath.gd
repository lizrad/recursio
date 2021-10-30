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
	var color_scheme = "player_" if selected else "player_ghost_"
	var wall_index = Constants.get_value("ghosts","wall_placing_ghost_index")
	var accent_type = "primary_accent" if wall_index != index else "secondary_accent"
	accent_type = "main" if selected else accent_type
	var color = Color(Constants.get_value("colors", color_scheme+accent_type))
	$Path/CSGPolygon.material_override.albedo_color = color
