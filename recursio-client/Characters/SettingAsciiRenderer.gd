extends MeshInstance


func _ready():
	var x_size = UserSettings.get_setting("video", "ascii_size")
	get_surface_material(0).set_shader_param("character_size", Vector2(x_size, x_size * 2))
