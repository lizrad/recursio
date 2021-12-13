extends MeshInstance


var looking_at: Array

var arrow = preload("res://Characters/Visuals/VisibleArrow.tscn")
onready var tween = get_node("Tween")


func set_visible(is_visible):
	if is_inside_tree():
		if not visible and is_visible:
			tween.interpolate_property(self, "scale",
				null, Vector3(1, 1, 1), 0.2,
				Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
			tween.start()
			visible = true
		elif visible and not is_visible:
			tween.interpolate_property(self, "scale",
				null, Vector3(0.01, 0.01, 0.01), 0.2,
				Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
			tween.start()
			yield(tween, "tween_completed")
			visible = false
	else:
		visible = is_visible


func set_looking_at_positions(positions):
	looking_at = positions


func _process(delta):
	for child in $Arrows.get_children():
		child.free()
	
	for pos in looking_at:
		var new_arrow = arrow.instance()
		$Arrows.add_child(new_arrow)
		new_arrow.look_at(pos, Vector3.UP)
