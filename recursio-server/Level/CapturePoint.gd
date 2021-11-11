class_name CapturePoint
extends Spatial

signal capture_team_changed(team_id)
signal captured(team_id)
signal capture_status_changed(capture_progress, team_id)
signal capture_lost(team_id)

var active = true
var capture_progress: float = 0
var _just_reset := false

var _current_progress_team = -1
var current_owning_team = -1

onready var _capture_speed: float = Constants.get_value("capture","capture_speed")
onready var _recapture_speed: float = Constants.get_value("capture","recapture_speed")
onready var _release_speed: float = Constants.get_value("capture","release_speed")


func _physics_process(delta):
	if not active:
		return
	
	if _just_reset:
		_just_reset = false
		return
	
	var bodies_inside = $Area.get_overlapping_bodies()
	var current_capture_team = -1
	
	for body in bodies_inside:
		var character = body.get_parent()
		if character is CharacterBase:
			if current_capture_team < 0:
				current_capture_team = character.team_id
			else:
				if current_capture_team != character.team_id:
					# Multiple different teams on here -> just return
					return
	
	if current_capture_team >= 0:
		# A player is standing on the capture point
		if current_owning_team != current_capture_team and current_owning_team >= 0:
			# The point is being taken from an enemy team
			_lose_capture()
		
		if current_capture_team == _current_progress_team:
			# The capturing player is equal to the progressing team
			if capture_progress < 1:
				capture_progress = min(1, capture_progress + delta * _capture_speed)
				emit_signal("capture_status_changed", capture_progress, _current_progress_team)
				
				if capture_progress >= 1:
					# The team has finished capturing the point
					_gain_capture(current_capture_team)
		else:
			# The capturing team differs from the previous owner
			capture_progress = max(0, capture_progress - delta * _recapture_speed)
			emit_signal("capture_status_changed", capture_progress, _current_progress_team)
			
			if capture_progress <= 0:
				# The capturing team becomes the progressing team
				_switch_capturer(current_capture_team)
	else:
		# No player is standing on the capture point
		if current_owning_team >= 0:
			_lose_capture()
		
		if capture_progress > 0:
			capture_progress = max(0, capture_progress - delta * _release_speed)
			emit_signal("capture_status_changed", capture_progress, _current_progress_team)
			
			if capture_progress <= 0:
				_switch_capturer(-1)


func _lose_capture():
	emit_signal("capture_lost", current_owning_team)
	current_owning_team = -1


func _gain_capture(new_owning_team):
	current_owning_team = new_owning_team
	emit_signal("captured", current_owning_team)


func _switch_capturer(new_progress_team):
	emit_signal("capture_status_changed", capture_progress, new_progress_team)
	emit_signal("capture_team_changed", new_progress_team)
	_current_progress_team = new_progress_team


func reset():
	if current_owning_team >= 0:
		emit_signal("capture_lost", current_owning_team)
	
	current_owning_team = -1
	capture_progress = 0
	_just_reset = true
	
	emit_signal("capture_team_changed", -1)
	emit_signal("capture_status_changed", 0, -1)
