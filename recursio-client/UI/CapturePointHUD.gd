extends Control
class_name CapturePointHUD

# The name of this capture point
onready var _name: Label = get_node("AspectRatioContainer/Control/TextureRect/CapturePointName")
# The progress display of this capture point
onready var _progress_bar: TextureProgress = get_node("AspectRatioContainer/TextureProgress")

onready var _background: TextureRect = get_node("AspectRatioContainer/Control/TextureRect")

var _player_id :int = -1
var _current_capture_team :int = -1


func set_player_id(player_id):
	_player_id = player_id


func update_status(progress, team):
	_progress_bar.value = progress
	if _current_capture_team == team:
		return
	_current_capture_team = team
	_background.modulate = Color.gray if team == -1 else Color.green if team == _player_id else Color.red

func set_name(new_name):
	_name.text = new_name
