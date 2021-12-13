extends Spatial
class_name SpawnPoint

var _tex_wall = preload("res://Resources/Icons/wall.png")
var _tex_bullet = preload("res://Resources/Icons/bullet.png")

export var active = false

# TODO: use ctor
func set_type(type) -> void:
	var idx_wall = Constants.get_value("ghosts", "wall_placing_timeline_index")
	# TODO: get color and texture from already instantiated action?
	$SpriteType.material_override.set_shader_param("albedo", _tex_wall if type == idx_wall else _tex_bullet)
	$SpriteType/SpriteBG.modulate = Color(Constants.get_value("colors", "player_" + ("secondary" if type == idx_wall else "primary") + "_accent"))
	set_active(false)


# rotate whole control but keep icons aligned
func rotate_ui(degrees) -> void:
	rotation_degrees.y = degrees
	$SpriteType.rotate_y(deg2rad(-degrees))


func set_active(value) -> void:
	active = value
	$SpriteArea.modulate = Color(Constants.get_value("colors", "selection")) if value else Color.gray
	$SpriteType.material_override.set_shader_param("is_greyscale", !value)


func show_weapon_type(value) -> void:
	$SpriteType.visible = value
