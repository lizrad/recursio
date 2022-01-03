tool
extends Label
class_name DynamicLabel

export(bool) var enable_this_after_font_is_unique: bool = false
export(int) var font_size_min: int = 2
export(int) var font_size_max: int = 72
# The font gives chars a different width, 
# therefore setting the pixel size of the font does not match the actual size
# TODO: Actual size of the font should be used
export(float) var font_char_scale: float = 1.4


func _process(_delta):
	if not enable_this_after_font_is_unique:
		return
	
	_update_font_size()


func _update_font_size():
	var font = self.get("custom_fonts/font")
	var new_font_size = (self.rect_size.x / self.text.length()) * font_char_scale
	font.size = min(max(new_font_size, font_size_min), font_size_max)
