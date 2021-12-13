extends MeshInstance


var looking_at: Array
var should_be_visible = false

var arrow = preload("res://Characters/Visuals/VisibleArrow.tscn")
onready var tween = get_node("Tween")


func set_visible(is_visible):
	# Lerp to visible or invisible
	if is_inside_tree():
		if not should_be_visible and is_visible:
			tween.interpolate_property(self, "scale",
				null, Vector3(1, 1, 1), 0.2,
				Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
			tween.start()
			should_be_visible = true
		elif should_be_visible and not is_visible:
			tween.interpolate_property(self, "scale",
				null, Vector3(0.01, 0.01, 0.01), 0.3,
				Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
			tween.start()
			yield(tween, "tween_completed")
			should_be_visible = false
	else:
		should_be_visible = is_visible
		scale = Vector3(0.01, 0.01, 0.01)


func set_looking_at_positions(positions):
	looking_at = positions


func _process(delta):
	for child in $Arrows.get_children():
		child.free()
	
	for pos in looking_at:
		var new_arrow = arrow.instance()
		$Arrows.add_child(new_arrow)
		new_arrow.look_at(pos, Vector3.UP)
