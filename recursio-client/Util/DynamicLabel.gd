tool
extends Label
class_name DynamicLabel

export(bool) var enable_this_after_font_is_unique: bool = false
export(Vector2) var resolution: Vector2 = Vector2(1920, 1080)
export(int) var font_size: int = 20


func _process(_delta):
	if not enable_this_after_font_is_unique:
		return
	
	_update_font_size()


func _update_font_size():
	var font = self.get("custom_fonts/font")
	
	var viewport_size = get_viewport_rect().size
	# Use average of vertical and horizontal difference
	var diff = viewport_size.x / resolution.x + viewport_size.y / resolution.y
	diff /= 2
	
	var new_font_size = font_size * diff
	font.size = new_font_size
