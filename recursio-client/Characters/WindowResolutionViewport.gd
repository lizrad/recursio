extends Viewport


func _ready():
	get_tree().get_root().connect("size_changed", self, "resize_viewport")
	resize_viewport()


func resize_viewport():
	var resolution = OS.get_window_size()
	size = resolution 
