extends Spatial
class_name SpawnPoint

var _tex_wall = preload("res://Resources/Icons/wall.png")
var _tex_bullet = preload("res://Resources/Icons/bullet.png")
var _highlight_icon_color_name: String

export var active = false

# TODO: use ctor
func set_type(type) -> void:
	var idx_wall = Constants.get_value("ghosts", "wall_placing_timeline_index")
	# TODO: get color and texture from already instantiated action?
	$SpriteType.material_override.set_shader_param("albedo", _tex_wall if type == idx_wall else _tex_bullet)
	_highlight_icon_color_name = "player_" + ("secondary" if type == idx_wall else "primary") + "_accent"
	ColorManager.color_object_by_method(_highlight_icon_color_name, $SpriteType.material_override, "set_shader_param",["color"])
	set_active(false)


# rotate whole control but keep icons aligned
func rotate_ui(degrees) -> void:
	rotation_degrees.y = degrees
	$SpriteType.rotate_y(deg2rad(-degrees))


func set_active(value) -> void:
	active = value
	var outline_color_name = "highlight" if value else "default"
	ColorManager.color_object_by_property(outline_color_name, $SpriteArea, "modulate")
	ColorManager.color_object_by_method(_highlight_icon_color_name, $SpriteType.material_override, "set_shader_param",["color"])
	var highlight_saturation = 1.5
	var inactive_saturation = 0.25
	$SpriteType.material_override.set_shader_param("saturation_modifier", highlight_saturation if value else inactive_saturation)


func show_weapon_type(value) -> void:
	$SpriteType.visible = value
