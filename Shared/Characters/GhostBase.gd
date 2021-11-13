extends CharacterBase
class_name GhostBase


var _is_playing: bool = false
var _record_data: RecordData
var _current_frame_index: int = -1
var _start_time: int = -1


func ghost_base_init(action_manager, record_data: RecordData) -> void:
	_record_data = RecordData.new().copy(record_data)
	timeline_index = record_data.timeline_index
	.character_base_init(action_manager)


# OVERRIDE #
func reset() -> void:
	.reset()
	_is_playing = false
	_current_frame_index = -1
	_start_time = -1


# Goes through the record and applies each frame
func _physics_process(_delta):
	if not _is_playing:
		return

	if _current_frame_index >= _record_data.record_frames.size():
		return
	
	var time_diff = _start_time - _record_data.record_frames[0].timestamp
	while _current_frame_index < _record_data.record_frames.size():
		
		var frame: RecordFrame = _record_data.record_frames[_current_frame_index]
		if frame.timestamp + time_diff > get_tree().get_root().get_node("Server").get_server_time():
			break

		_apply_record_frame(frame)
		_current_frame_index += 1


# Stops the ghost and triggers the base classes hit function
# OVERRIDE #
func hit() -> void:
	stop_playing()
	.hit()


# Starts moving the ghost and enables collision
func start_playing(start_time: int) -> void:
	_is_playing = true
	_collision_shape.disabled = false
	_current_frame_index = 0
	_start_time = start_time

# Stops moving the ghost and disables collision
func stop_playing() -> void:
	_is_playing = false
	_collision_shape.disabled = true


# Applies the given frame
func _apply_record_frame(record_frame: RecordFrame):
	.set_position(record_frame.position)
	.set_rotation_y(record_frame.rotation_y)
	.trigger_actions(record_frame.buttons)
