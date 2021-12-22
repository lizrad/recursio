extends VBoxContainer
class_name StatsUI


onready var _visualisation = get_node("Values/Visualisation")

func _ready():
	ColorManager.color_object_by_property("player_main", _visualisation.get("custom_styles/fg"), "bg_color")
	ColorManager.color_object_by_property("enemy_main", _visualisation.get("custom_styles/bg"), "bg_color")
	

func set_title(title: String) -> void:
	$Descriptions/Space/Title.text = title

func set_descriptions(left_description: String, right_description: String) -> void:
	$Descriptions/LeftDescription.text = left_description
	$Descriptions/RightDescription.text = right_description

func set_values(left_value: int, right_value: int) -> void:
	$Values/LeftValue.text = str(left_value)
	$Values/RightValue.text = str(right_value)
	$Values/Visualisation.value = 100.0*(float(left_value)/float(left_value+right_value))
