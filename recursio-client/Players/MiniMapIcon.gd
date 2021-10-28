tool
extends Spatial


export var texture: Texture

onready var camera_size = Constants.get_value("visibility", "camera_size")

var visibility_mask: Texture


func _ready():
	$Sprite.texture = texture


func _process(_delta):
	if visibility_mask:
		_check_for_visibility()


func _check_for_visibility()->void:
	var uv = Vector2(global_transform.origin.x, global_transform.origin.z);
	uv += Vector2(camera_size / 2.0, camera_size / 2.0);
	uv /= camera_size;
	uv.y = 1.0 - uv.y;

	var resolution = visibility_mask.get_data().get_size()
	var visibility_image = visibility_mask.get_data()
	visibility_image.lock()
	var pixel = visibility_image.get_pixel(uv.x * resolution.x, uv.y * resolution.y)
	visibility_image.unlock()
	
	visible = pixel.gray() > 0.05


func set_texture(tex : Texture)->void:
	texture = tex
	$Sprite.texture = texture
