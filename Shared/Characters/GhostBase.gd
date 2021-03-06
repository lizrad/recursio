extends CharacterBase
class_name GhostBase

var _is_active = true
var _is_playing: bool = false
var _record_data: RecordData = null
var _current_frame_index: int = -1
var _start_time: int = -1


func init(action_manager, player_id, team_id, timeline_index, spawn_point) -> void:
	self.player_id = player_id
	self.team_id = team_id
	self.timeline_index = timeline_index
	self.spawn_point = spawn_point.global_transform.origin
	.character_base_init(action_manager)

func set_record_data(record_data):
	_record_data = RecordData.new().copy(record_data)

func clear_record_data():
	_record_data = null

func is_active() -> bool:
	return _is_active
func is_playing() -> bool:
	return _is_playing

func is_record_data_set() -> bool:
	return _record_data != null

# Goes through the record and applies each frame
func update(_delta):
	if not _is_active:
		return
	if not _is_playing:
		return
	# this should only run when we have record data
	assert(is_record_data_set())

	if _current_frame_index >= _record_data.record_frames.size():
		return
	
	var time_diff = _start_time - _record_data.timestamp
	while _current_frame_index < _record_data.record_frames.size():
		
		var frame: RecordFrame = _record_data.record_frames[_current_frame_index]
		if frame.timestamp + time_diff > get_tree().get_root().get_node("Server").get_server_time():
			break

		_apply_record_frame(frame)
		_current_frame_index += 1


# Stops the ghost and triggers the base classes hit function
# OVERRIDE #
func hit(hit_data: HitData) -> void:
	_is_playing = false
	.hit(hit_data)

# OVERRIDE #
func quiet_hit(hit_data: HitData) -> void:
	_is_playing = false
	.quiet_hit(hit_data)
	
# Starts moving the ghost and enables collision
func start_playing(start_time: int) -> void:
	_is_playing = true
	_current_frame_index = 0
	_start_time = start_time


# Stops moving the ghost and disables collision
func stop_playing() -> void:
	_is_playing = false


# Applies the given frame
func _apply_record_frame(record_frame: RecordFrame):
	var prev_position = get_position()
	.set_position(record_frame.position)
	.set_rotation_y(record_frame.rotation_y)
	.trigger_actions(record_frame.buttons)
	# TODO: this is pretty wonky but I don't really know a better way to react to this without rewriting the whole recording system
	# and it works well enough for the tutorial, which is the only place using this signal for now
	if (prev_position-record_frame.position).length() >= 1.0:
		if (record_frame.position-spawn_point).length() < 0.3:
			emit_signal("respawned")


func enable_body():
	assert(is_record_data_set())
	_is_active = true
	kb.visible = true
	_collision_shape.disabled = false
	#_minimap_icon.set_texture(_minimap_alive)


func disable_body():
	_is_active = false
	kb.visible = false
	_collision_shape.disabled = true

# OVERRIDE #
func visual_delayed_spawn(delay: float):
	if not _is_active:
		return
	.visual_delayed_spawn(delay)

# OVERRIDE #
func visual_kill():
	if not _is_active:
		return
	.visual_kill()
