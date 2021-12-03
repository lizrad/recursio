extends Spatial
class_name SpawnPoint

var _tex_wall = preload("res://Shared/Actions/Shots/wall.png")
var _tex_bullet = preload("res://Shared/Actions/Shots/bullet.png")

# TODO: use ctor
func set_type(type) -> void:
	var idx_wall = Constants.get_value("ghosts", "wall_placing_timeline_index")
	# TODO: get color and texture from already instantiated action?
	$SpriteType.texture = _tex_wall if type == idx_wall else _tex_bullet
	$SpriteType/SpriteBG.modulate = Color(Constants.get_value("colors", "player_" + ("secondary" if type == idx_wall else "primary") + "_accent"))
	set_active(true)


# rotate whole control but keep icons aligned
func rotate_ui(degrees) -> void:
	rotation_degrees.y = degrees
	$SpriteType.rotate_y(deg2rad(-degrees))


func set_active(value) -> void:
	$SpriteArea.modulate = Color("#FF9AFF") if value else Color.yellow
	# TODO: set grayscale for image in SpriteType and SpriteBG
	# 		if using a shader gets complicated just use different textures

