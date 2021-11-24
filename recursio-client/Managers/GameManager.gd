extends Node
class_name GameManager

onready var _game_result_screen = get_node("../../GameResultScreen")
onready var _countdown_screen = get_node("../../CountdownScreen")

var _level: Level
var _team_id := -1
var _countdown_time: float = Constants.get_value("gameplay","countdown_phase_seconds")

func _ready():
	# Hide screens
	_game_result_screen.visible = false
	_countdown_screen.visible = false
	
	var _error = Server.connect("capture_point_captured", self, "_on_capture_point_captured") 
	_error = Server.connect("capture_point_team_changed", self, "_on_capture_point_team_changed") 
	_error = Server.connect("capture_point_status_changed", self, "_on_capture_point_status_changed") 
	_error = Server.connect("capture_point_capture_lost", self, "_on_capture_point_capture_lost") 


func _process(delta):
	if _countdown_screen.visible:
		_countdown_screen.update_text(int(_countdown_time))
		_countdown_time -= delta
		# Hide if countdown is finished
		if _countdown_time <= 0.0:
			hide_countdown_screen()


func set_level(level: Level):
	_level = level


func show_countdown_screen() -> void:
	_countdown_screen.visible = true


func hide_countdown_screen() -> void:
	_countdown_screen.visible = false
	_countdown_time = Constants.get_value("gameplay","countdown_phase_seconds")


func hide_game_result_screen() -> void:
	_game_result_screen.visible = false


func show_win() -> void:
	Logger.info("Player won!", "gameplay")
	_game_result_screen.get_node("ResultText").text = "You Won!"
	_game_result_screen.visible = true


func show_loss() -> void:
	Logger.info("Player lost!", "gameplay")
	_game_result_screen.get_node("ResultText").text = "You Lost!"
	_game_result_screen.visible = true


func get_spawn_point(team_id, timeline_index) -> Vector3:
	return _level.get_spawn_points(team_id)[timeline_index]


func get_capture_points() -> Array:
	return _level.get_capture_points()


func toggle_spawn_points(toggle: bool) -> void:
	_level.toggle_spawn_points(toggle)
	
	
func toggle_capture_points(toggle: bool) -> void:
	_level.toggle_capture_points(toggle)

func set_team_id(team_id):
	_team_id = team_id
	_level.color_spawn_points(_team_id)

func reset() -> void:
	_game_result_screen.visible = false
	_countdown_screen.visible = false
	# Reset level
	_level.reset()
	_level.toggle_capture_points(false)
	_level.toggle_spawn_points(true)


func _on_capture_point_captured(capturing_player_id, capture_point):
	_level.get_capture_points()[capture_point].capture(capturing_player_id)


func _on_capture_point_team_changed(capturing_player_id, capture_point):
	_level.get_capture_points()[capture_point].set_capturing_player(capturing_player_id)


func _on_capture_point_status_changed(capturing_player_id, capture_point, capture_progress):
	_level.get_capture_points()[capture_point].set_capture_status(capturing_player_id, capture_progress)


func _on_capture_point_capture_lost(capturing_player_id, capture_point):
	_level.get_capture_points()[capture_point].capture_lost(capturing_player_id)

