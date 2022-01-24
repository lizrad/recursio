extends HBoxContainer

onready var _goal_text: Label = get_node("GoalText")
var _camera: Camera
var _goal: Node
func init(camera: Camera) -> void:
	_camera = camera


func _process(_delta) -> void:
	if _goal:
		_update_position()


func set_content(text: String, goal: Node) -> void:
	_goal_text.text = text
	_goal = goal
	_update_position()


func _update_position() -> void:
	var offset = Vector3(1.5, 0.0, 0.0)
	if _goal is Spatial:
		rect_position = _camera.unproject_position(_goal.global_transform.origin + offset)
	elif _goal is Control:
		rect_position = _goal.get_global_rect().position
		rect_position += _goal.rect_size
	rect_position.y -= rect_size.y * 0.5
