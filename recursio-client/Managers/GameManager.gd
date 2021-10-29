extends Node
class_name GameManager

export var level_path: NodePath

onready var _game_result_screen = get_node("../GameResultScreen")
onready var _countdown_screen = get_node("../CountdownScreen")
onready var _countdown_screen_text = _countdown_screen.get_node("CountdownText")
onready var _level: Level = get_node(level_path)

var _countdown_time: float = 0.0

func _ready():
	# Hide screens
	_game_result_screen.visible = false
	_countdown_screen.visible = false


func _process(delta):	
	if _countdown_screen.visible:
		_countdown_screen_text.text = str(int(_countdown_time))
		_countdown_time -= delta
		# Hide if countdown is finished
		if _countdown_time <= 0.0:
			_countdown_screen.visible = false


func show_countdown_screen(countdown_time) -> void:
	_countdown_screen.visible = true
	_countdown_time = countdown_time


func hide_countdown_screen() -> void:
	_countdown_screen.visible = false


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


func toggle_capture_points(toggle: bool) -> void:
	_level.toggle_capture_points(toggle)


func reset() -> void:
	_game_result_screen.visible = false
	_countdown_screen.visible = false
	# Reset level
	_level.reset()
	_level.toggle_capture_points(false)



