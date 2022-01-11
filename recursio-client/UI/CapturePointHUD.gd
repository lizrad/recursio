extends Control
class_name CapturePointHUD

# The name of this capture point
onready var _name: Label = get_node("AspectRatioContainer/Control/TextureRect/CapturePointName")
# The progress display of this capture point
onready var _progress_bar: TextureProgress = get_node("AspectRatioContainer/TextureProgress")
onready var _background: TextureRect = get_node("AspectRatioContainer/Control/TextureRect")

onready var neutral_color_name = "default"
onready var player_color_name = "player_main"
onready var enemy_color_name = "enemy_main"

var _player_id: int = -1
var _player_team_id: int = -1
var _current_capture_team: int = -1


func _ready():
	reset()


func reset():
	_progress_bar.value = 0
	ColorManager.color_object_by_property(neutral_color_name, _background, "modulate")


func set_player_id(player_id):
	_player_id = player_id

func set_player_team_id(team_id):
	_player_team_id = team_id


func update_status(progress, team):
	_progress_bar.value = progress

	# bugfix because Nine Patch Stretch is buggy in Godot3.4 for clockwise fillmodes
	_progress_bar.fill_mode = TextureProgress.FILL_CLOCKWISE if progress < 1 else TextureProgress.FILL_LEFT_TO_RIGHT

	if _current_capture_team == team:
		return

	_current_capture_team = team
	var color_name = neutral_color_name if team == -1 else player_color_name if team == _player_team_id else enemy_color_name
	ColorManager.color_object_by_property(color_name, _background, "modulate")


func set_name(new_name):
	_name.text = new_name
