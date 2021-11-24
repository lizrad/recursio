extends BaseAnimator

onready var _wall_particles = get_node("../RootPivot/MiddlePivot/WallParticles")

export var animation_duration := 0.5


var _time_since_start = 0
var _particles_played = false

func _ready():
	var _error =  get_parent().connect("color_scheme_changed",self,"_on_color_scheme_changed")
	_wall_particles.lifetime = animation_duration;

func _on_color_scheme_changed(new_color_scheme, _timeline_index):
	var accent_color = Color(Constants.get_value("colors",new_color_scheme + "_secondary_accent"))
	_wall_particles.material_override.albedo_color = accent_color
	_wall_particles.material_override.emission = accent_color

func start_animation():
	_time_since_start = 0
	_particles_played = false

func get_keyframe(delta):
	_reset_keyframes()
	_time_since_start += delta
	if _time_since_start > animation_duration:
		emit_signal("animation_over")
		_time_since_start = animation_duration
	var ratio = _time_since_start/animation_duration
	if ratio >= 0.5 and not _particles_played:
		_wall_particles.restart()
		_particles_played = true
	
	var remapped_ratio = abs(1-2*pow(1-ratio,2))
	var scale = Vector3(remapped_ratio,remapped_ratio,remapped_ratio)
	_keyframes[_middle_pivot].basis = _keyframes[_front_pivot].basis.scaled(scale)
	return _keyframes
