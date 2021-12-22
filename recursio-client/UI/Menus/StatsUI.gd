extends VBoxContainer
class_name StatsUI


onready var _visualisation: ProgressBar = get_node("Values/Visualisation")
onready var _title: Label = get_node("Descriptions/Space/Title")
onready var _left_description: Label = get_node("Descriptions/LeftDescription")
onready var _right_description: Label = get_node("Descriptions/RightDescription")
onready var _left_value: Label = get_node("Values/LeftValue")
onready var _right_value: Label = get_node("Values/RightValue")

func _ready() -> void:
	ColorManager.color_object_by_property("player_main", _visualisation.get("custom_styles/fg"), "bg_color")
	ColorManager.color_object_by_property("enemy_main", _visualisation.get("custom_styles/bg"), "bg_color")
	

func set_title(title: String) -> void:
	_title.text = title

func set_descriptions(left_description: String, right_description: String) -> void:
	_left_description.text = left_description
	_right_description.text = right_description

func set_values(left_value: int, right_value: int) -> void:
	_left_value.text = str(left_value)
	_right_value.text = str(right_value)
	_visualisation.value = 100.0*(float(left_value)/float(left_value+right_value))
