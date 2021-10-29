extends Ghost
class_name PlayerGhost

onready var _path_scene = preload("res://Rendering/GhostPath.tscn").instance()
var _path: Curve3D

func create_path():
		_path = Curve3D.new()
		
		for frame in range(0, _record_data.record_frames.size(), 30):
			var record_frame: RecordFrame = _record_data.record_frames[frame]
			_path.add_point(record_frame.position)
		
		_path_scene.set_curve(_path)
		_path_scene.set_color_for_index(timeline_index)
		add_child(_path_scene)

func delete_path():
	_path_scene.queue_free()
