extends Control
class_name CapturePointHUD

# The name of this capture point
onready var _name: Label = get_node("AspectRatioContainer/Control/TextureRect/CapturePointName")
# The progress display of this capture point
onready var _progress_bar: TextureProgress = get_node("AspectRatioContainer/TextureProgress")

onready var _background: TextureRect = get_node("AspectRatioContainer/Control/TextureRect")

onready var neutral_color = Color(Constants.get_value("colors", "neutral"))
onready var player_color = Color(Constants.get_value("colors", "player_main"))
onready var enemy_color = Color(Constants.get_value("colors", "enemy_main"))

var _player_id :int = -1
var _current_capture_team :int = -1

func _ready():
	reset()

func reset():
	_progress_bar.value = 0
	_background.modulate = neutral_color

func set_player_id(player_id):
	_player_id = player_id


func update_status(progress, team):
	_progress_bar.value = progress
	if _current_capture_team == team:
		return
	_current_capture_team = team
	_background.modulate = neutral_color if team == -1 else player_color if team == _player_id else enemy_color

func set_name(new_name):
	_name.text = new_name
