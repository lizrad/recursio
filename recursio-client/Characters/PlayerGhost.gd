extends Ghost
class_name PlayerGhost


func player_ghost_init(action_manager, record_data: RecordData, color_scheme: String) -> void:
	.ghost_init(action_manager, record_data, color_scheme)


func create_path():
		var _curve = Curve3D.new()
		
		for frame in range(0, _record_data.record_frames.size(), 30):
			var record_frame: RecordFrame = _record_data.record_frames[frame]
			_curve.add_point(record_frame.position)
		
		$GhostPath.set_curve(_curve)
		$GhostPath.set_color_for_index(timeline_index)


func delete_path():
	$GhostPath.set_curve(Curve.new())
