extends Spatial
class_name Level


# Scene to add to the capture and spawn points for logic
# defined in UI/Menus/StartMenu for client
# 		 and GameRoom/GameRoom for server
export var capture_point_scene: PackedScene
var _capture_points = []

# spawn point visuals for client
export var spawn_point_scene: PackedScene

func _ready():
	if not capture_point_scene:
		Logger.error("No Capture Point Scene! Capture Points will not work")
		return

	for point in $CapturePoints.get_children():
		var new_scene = capture_point_scene.instance()
		_capture_points.append(new_scene)
		point.add_child(new_scene)

	if not spawn_point_scene:
		Logger.error("No valid Spawn Point Scene! Spawn Points will not work")
		return

	# client only properties -> server does not need any visuals
	var max_ghosts = Constants.get_value("ghosts", "max_amount")
	for player in range(2):
		var spawns = get_node("Player" + str(player + 1) + "Spawns")
		for spawn in spawns.get_children():
			var new_scene = spawn_point_scene.instance()
			# TODO: could check if configured scene is valid
			#if new_scene.has_method("set_type"):

			# set action type depending on point index
			new_scene.set_type(spawn.get_index() % max_ghosts)
			# rotate depending on player index: 0 starts left, 1 right
			new_scene.rotate_ui(player * 180)
			# only activate for current player in prep phase

			spawn.add_child(new_scene)


func reset():
	for capture_point in _capture_points:
		capture_point.reset()
	toggle_capture_points(false)
	toggle_spawn_points(true)


func get_spawn_points(team_id):
	var node_name = "Player" + str(team_id + 1) + "Spawns"
	if has_node(node_name):
		var spawn_points = []
		for point in get_node(node_name).get_children():
			spawn_points.append(point)
		return spawn_points
	else:
		Logger.error("Tried to get spawn positions for invalid node " + node_name)
		return null


func get_spawn_point_node(team_id: int, timeline_index: int ) -> SpawnPoint:
	var node_name = "Player" + str(team_id + 1) + "Spawns"
	if has_node(node_name):
		return get_node(node_name).get_children()[timeline_index].get_children()[0]
	else:
		Logger.error("Spawn point does not exist." + node_name)
		return null

func get_capture_points():
	return _capture_points


func toggle_spawn_points(toggle: bool) -> void:
	Logger.info("Toggling spawn points " + ("on" if toggle else "off") + ".", "spawn_point")
	for player in range(2):
		var spawns = "Player" + str(player + 1) + "Spawns"
		if has_node(spawns):
			for spawn in get_node(spawns).get_children():
				spawn.visible = toggle


func show_spawn_point_weapon_type(team_id) -> void:
	var spawns = "Player" + str(team_id + 1) + "Spawns"
	if has_node(spawns):
		for spawn in get_node(spawns).get_children():
			if spawn.has_node("SpawnPoint"):
				spawn.get_node("SpawnPoint").show_weapon_type(true)


func toggle_capture_points(toggle: bool) -> void:
	Logger.info("Toggling capture points " + ("on" if toggle else "off") + ".", "capture_point")
	for capture_point in _capture_points:
		capture_point.active = toggle


func set_team_id(team_id: int) -> void:
	for capture_point in _capture_points:
		if "player_team_id" in capture_point:
			capture_point.player_team_id = team_id
