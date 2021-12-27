extends HBoxContainer

onready var _goal_text: Label = get_node("GoalText")
var _camera: Camera
var _goal: Spatial
func init(camera: Camera):
	_camera = camera

func set_goal(goal: Spatial):
	_goal = goal
	_update_position()
	
func set_text(text: String):
	_goal_text.text = text

func _process(_delta):
	if _goal:
		_update_position()

func _update_position():
	rect_position = _camera.unproject_position(_goal.global_transform.origin)
	rect_position.y -= rect_size.y * 0.5
