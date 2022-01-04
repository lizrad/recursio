extends HBoxContainer

onready var _goal_text: Label = get_node("GoalText")
var _camera: Camera
var _goal: Spatial


func init(camera: Camera) -> void:
	_camera = camera


func _process(_delta) -> void:
	if _goal:
		_update_position()


func set_content(text: String, goal: Spatial) -> void:
	_goal_text.text = text
	_goal = goal
	_update_position()


func _update_position() -> void:
	rect_position = _camera.unproject_position(_goal.global_transform.origin)
	rect_position.y -= rect_size.y * 0.5
