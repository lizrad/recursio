extends MeshInstance


var looking_at: Array
var should_be_visible = false

var arrow = preload("res://Characters/Visuals/VisibleArrow.tscn")
onready var tween = get_node("Tween")


func _ready():
	var color_name = "negative"
	ColorManager.color_object_by_property(color_name, material_override, "albedo_color")


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


func _process(_delta):
	# Spawn and position arrows
	if $Arrows.get_children().size() == looking_at.size():
		# If we already have the number of arrows we need, just reposition them
		for i in range(looking_at.size()):
			$Arrows.get_child(i).look_at(looking_at[i], Vector3.UP)
	else:
		# For simplicity, just free all arrows and instantiate new ones. Could be optimized, but
		# doesn't seem like a bottleneck
		for child in $Arrows.get_children():
			child.free()
		
		for pos in looking_at:
			var new_arrow = arrow.instance()
			$Arrows.add_child(new_arrow)
			new_arrow.look_at(pos, Vector3.UP)
