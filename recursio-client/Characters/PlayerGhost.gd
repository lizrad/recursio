extends Ghost
class_name PlayerGhost

onready var _visibility_light = get_node("KinematicBody/VisibilityLight")

# OVERRIDE #
func init(action_manager, player_id, team_id, timeline_index, spawn_point) -> void:
	.init(action_manager, player_id, team_id, timeline_index, spawn_point)
	_character_model._set_color_scheme("player_ghost", timeline_index)


func toggle_visibility_light(value: bool):
	_visibility_light.toggle(value)


func create_path():
	if not is_record_data_set():
		return
	var _curve = Curve3D.new()
	for frame in range(0, _record_data.record_frames.size(), 30):
		var record_frame: RecordFrame = _record_data.record_frames[frame]
		_curve.add_point(record_frame.position)
	$GhostPath.set_curve(_curve)
	toggle_path_select(false)
	$GhostPath.index = timeline_index


func toggle_path_select(value):
		$GhostPath.selected = value

func delete_path():
	$GhostPath.set_curve(Curve.new())
