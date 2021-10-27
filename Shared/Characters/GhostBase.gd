extends CharacterBase
class_name GhostBase


var _is_playing: bool = false

var _record_data: RecordData
var _current_frame_index: int = -1
var _start_time: int = -1


func _init(action_manager : ActionManager, record_data: RecordData).(action_manager):
	_record_data = RecordData.new().copy(record_data)


func _physics_process(delta):
	if not _is_playing:
		return
	
	if _current_frame_index >= _record_data.record_frames.size():
		return
	
	var time_diff = _start_time - _record_data.timestamp
	while _current_frame_index < _record_data.record_frames.size():
		var frame: RecordFrame = _record_data.record_frames[_current_frame_index]
		if frame.timestamp + time_diff > Server.get_server_time():
			break
		
		


func start_playing(start_time: int) -> void:
	_is_playing = true
	_current_frame_index = 0
	_start_time = start_time


func _apply_record_frame(record_frame: RecordFrame):
	.set_position(record_frame.position)
	.set_rotation_y(record_frame.rotation_y)
	.trigger_actions(record_frame.buttons)
