extends Node
class_name GameManager

signal capture_point_team_changed(team_id, capture_point)
signal capture_point_captured(team_id, capture_point)
signal capture_point_status_changed(capture_progress, team_id, capture_point)
signal capture_point_capture_lost(team_id, capture_point)
signal game_result(team_id)

var _level setget set_level


func set_level(level):
	if _level:
		for i in range(_level.get_capture_points().size()):
			_level.get_capture_points()[i].disconnect("capture_status_changed", self, "_on_capture_status_changed")
			_level.get_capture_points()[i].disconnect("captured", self, "_on_captured")
			_level.get_capture_points()[i].disconnect("capture_team_changed",self, "_on_capture_team_changed")
			_level.get_capture_points()[i].disconnect("capture_lost",self, "_on_capture_lost")
		
	_level = level
	
	for i in range(_level.get_capture_points().size()):
		_level.get_capture_points()[i].connect("capture_status_changed", self, "_on_capture_status_changed", [i])
		_level.get_capture_points()[i].connect("captured", self, "_on_captured", [i])
		_level.get_capture_points()[i].connect("capture_team_changed",self, "_on_capture_team_changed", [i])
		_level.get_capture_points()[i].connect("capture_lost",self, "_on_capture_lost", [i])

# Called when the game_room is full
func start_game():
	# TODO: Do we need this?
	pass


func reset():
	for i in range(_level.get_capture_points().size()):
		_level.get_capture_points()[i].reset()


func get_spawn_point(team_id, timeline_index) -> Node:
	return _level.get_spawn_points(team_id)[timeline_index]


func start_round():
	_level.toggle_capture_points(true)


func end_round():
	_level.reset()


func _on_capture_status_changed(capture_progress, team_id, capture_point):
	emit_signal("capture_point_status_changed", capture_progress, team_id, capture_point)

func _on_captured(team_id, capture_point):
	emit_signal("capture_point_captured", team_id, capture_point)
	_check_for_win()

func _on_capture_team_changed(team_id, capture_point):
	emit_signal("capture_point_team_changed", team_id, capture_point)

func _on_capture_lost(team_id, capture_point):
	emit_signal("capture_point_capture_lost", team_id, capture_point)

func _check_for_win():
	var captured_points_score = [0,0]
	for capture_point in _level.get_capture_points():
		if capture_point.current_owning_team >= 0:
			captured_points_score[capture_point.current_owning_team] += 1
	
	var win_score = floor(_level.get_capture_points().size()*0.5)+1
	for i in range(captured_points_score.size()):
		if captured_points_score[i] >= win_score:
			emit_signal("game_result", i)
	




