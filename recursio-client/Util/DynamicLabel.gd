tool
extends Label
class_name DynamicLabel

export(bool) var enable_this_after_font_is_unique: bool = false
export(int) var font_size: int = 20
export(bool) var use_parent_for_scaling: bool = true


func _process(_delta):
	if not enable_this_after_font_is_unique:
		return
	
	_update_font_size()


func _update_font_size() -> void:
	var font = self.get("custom_fonts/font")
	var viewport_size = self.get_parent().rect_size if use_parent_for_scaling else get_viewport().get_visible_rect().size
	var diff = viewport_size.x / Constants.DEFAULT_WINDOW_WIDTH + viewport_size.y / Constants.DEFAULT_WINDOW_HEIGHT
	diff /= 2
	
	var new_font_size = font_size * diff
	font.size = new_font_size
