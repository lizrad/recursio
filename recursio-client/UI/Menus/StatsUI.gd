extends VBoxContainer
class_name StatsUI


func set_title(title: String) -> void:
	$Titel.text = title

func set_descriptions(left_description: String, right_description: String) -> void:
	$Descriptions/LeftDescription.text = left_description
	$Descriptions/RightDescription.text = right_description

func set_values(left_value: int, right_value: int) -> void:
	$Values/LeftValue.text = str(left_value)
	$Values/RightValue.text = str(right_value)
	$Values/Visualisation.value = 100.0*(float(left_value)/float(left_value+right_value))
