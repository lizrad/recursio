class_name ServerCapturePoint
extends BaseCapturePoint


signal capture_team_changed(team_id)
signal captured(team_id)
signal capture_status_changed(capture_progress, team_id)
signal capture_lost(team_id)


# OVERRIDE #
func reset()-> void:
	.reset()
	if current_owning_team >= 0:
		emit_signal("capture_lost", current_owning_team)
	emit_signal("capture_team_changed", -1)
	emit_signal("capture_status_changed", 0, -1)


# OVERRIDE #
func _change_capture_progress(progress: float) -> void:
	._change_capture_progress(progress)
	emit_signal("capture_status_changed", progress, _current_progress_team)


# OVERRIDE #
func _lose_capture() -> void:
	emit_signal("capture_lost", current_owning_team)
	._lose_capture()


# OVERRIDE #
func _gain_capture(new_owning_team: int) -> void:
	._gain_capture(new_owning_team)
	emit_signal("captured", new_owning_team)


# OVERRIDE #
func _switch_capturer(new_progress_team: int)-> void:
	._switch_capturer(new_progress_team)
	emit_signal("capture_status_changed", capture_progress, new_progress_team)
	emit_signal("capture_team_changed", new_progress_team)
