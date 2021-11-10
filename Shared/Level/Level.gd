extends Spatial
class_name Level


# Scene to add  to the capture points for logic
export var capture_point_scene: PackedScene
var _capture_points =[]

func _ready():
	if not capture_point_scene:
		Logger.error("No Capture Point Scene! Capture Points will not work")
		return
	else:
		for point in $CapturePoints.get_children():
			var new_scene = capture_point_scene.instance()
			new_scene.global_transform = point.global_transform
			_capture_points.append(new_scene)
			add_child(new_scene)
	

func color_spawn_points(player_team_id):
	for player in range(2):
		var spawns = "Player" + str(player + 1) + "Spawns"
		if has_node(spawns):
			var index = 0
			for spawn in get_node(spawns).get_children():
				var color_scheme = "player_" if player_team_id == player else "enemy_"
				var wall_index = Constants.get_value("ghosts","wall_placing_timeline_index")
				var accent_type = "primary" if wall_index != index else "secondary"
				var color = Color(Constants.get_value("colors", color_scheme+accent_type+"_accent"))
				spawn.get_node("MeshInstance").material_override.albedo_color = color
				index += 1

func reset():
	for capture_point in _capture_points:
		capture_point.reset()
	toggle_capture_points(false)

func get_spawn_points(team_id):
	var node_name = "Player" + str(team_id + 1) + "Spawns"
	if has_node(node_name):
		var spawn_positions = []
		for position in get_node(node_name).get_children():
			spawn_positions.append(position.global_transform.origin)

		return spawn_positions
	else:
		Logger.error("Tried to get spawn positions for invalid node " + node_name)
		return null


func get_capture_points():
	return _capture_points

func toggle_capture_points(toggle:bool) -> void:
	Logger.info("Toggling capture points " + ("on" if toggle else "off") + ".", "capture_point")
	for capture_point in _capture_points:
		capture_point.active = toggle

	# also toggle spawn points visuals
	for player in range(2):
		var spawns = "Player" + str(player + 1) + "Spawns"
		if has_node(spawns):
			for spawn in get_node(spawns).get_children():
				spawn.get_node("MeshInstance").visible = !toggle
