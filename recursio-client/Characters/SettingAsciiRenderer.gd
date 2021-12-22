extends MeshInstance


func _ready():
	update_ascii_size(UserSettings.get_setting("video", "ascii_size"))
	var _error = UserSettings.connect("setting_changed", self, "_on_setting_changed")


func _on_setting_changed(setting_header, setting_name, value):
	if setting_header == "video" and setting_name == "ascii_size":
		update_ascii_size(value)


func update_ascii_size(new_x_size):
	get_surface_material(0).set_shader_param("character_size", Vector2(new_x_size, new_x_size * 2))
