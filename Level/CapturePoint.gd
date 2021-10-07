extends Spatial


var _current_alignment = 0


func _ready():
	$Area.connect("body_entered", self, "_on_body_entered")
	$Area.connect("body_exited", self, "_on_body_exited")


func _on_body_entered(body):
	if body is Player:
		_current_alignment += 1
	elif body is Enemy:
		_current_alignment -= 1


func _on_body_exited(body):
	if body is Player:
		_current_alignment -= 1
	elif body is Enemy:
		_current_alignment += 1


func _process(delta):
	if _current_alignment > 0:
		$MeshInstance.material_override.albedo_color = Color.green
	elif _current_alignment < 0:
		$MeshInstance.material_override.albedo_color = Color.red
	else:
		$MeshInstance.material_override.albedo_color = Color.gray
