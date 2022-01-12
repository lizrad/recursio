extends Spatial
class_name LerpedFollow




export(NodePath) var target_node
onready var target = get_node(target_node)
onready var _tween = get_node("Tween")

export(float) var lerp_factor = 0.5
export(bool) var lock_y_rotation


var _following: bool = true
var _shake_vector: Vector3 = Vector3.ZERO
var _shake_amount: float = 0
var _shake_speed: float = 0

# Prevents potential race conditions
var _current_shake_count := 0


func _ready():
	var _error = PostProcess.connect("shaking_camera", self, "shake")


func stop_following():
	_following = false


func start_following():
	_following = true
	set_physics_process(true)


func shake(amount: float, speed: float, duration: float):
	start_shake(amount, speed)
	yield(get_tree().create_timer(duration), "timeout")
	stop_shake()


func start_shake(amount: float, speed: float):
	_current_shake_count += 1
	
	if not _tween.is_connected("tween_all_completed", self, "_on_shake_complete"):
		var _error = _tween.connect("tween_all_completed", self, "_on_shake_complete")
	_shake_amount = amount
	_shake_speed = speed
	_on_shake_complete()


func _start_shake_tween(start_vector: Vector3, goal_vector: Vector3):
	_tween.remove_all()
	var time = 1.0/_shake_speed
	_tween.interpolate_property(self,"_shake_vector", start_vector, goal_vector, time, Tween.TRANS_LINEAR, Tween.EASE_IN)
	_tween.start()


func _on_shake_complete():
	var start_vector = Vector3(_shake_vector.x, 0, _shake_vector.z)
	var goal_vector = Vector3(rand_range(-_shake_amount,_shake_amount),0,rand_range(-_shake_amount,_shake_amount))
	_start_shake_tween(start_vector, goal_vector)


func stop_shake():
	_current_shake_count -= 1
	
	# Only stop the shake if no one else is shaking the camera right now - this is to prevent cases
	# where two shakes are triggered shortly after each other, causing one to stop while the other
	# should still run
	if _current_shake_count == 0:
		_tween.disconnect("tween_all_completed", self, "_on_shake_complete")
		_tween.remove_all()
		var start_vector = Vector3(_shake_vector.x, 0, _shake_vector.z)
		var goal_vector = Vector3.ZERO
		_start_shake_tween(start_vector, goal_vector)

# stops all shakes
func hard_stop_shake():
	_current_shake_count = 0
	_shake_speed = 1
	_tween.disconnect("tween_all_completed", self, "_on_shake_complete")
	_tween.remove_all()
	var start_vector = Vector3(_shake_vector.x, 0, _shake_vector.z)
	var goal_vector = Vector3.ZERO
	_start_shake_tween(start_vector, goal_vector)


func _physics_process(_delta):
	if _following:
		global_transform = global_transform.interpolate_with(target.global_transform, lerp_factor)
	
	global_transform.origin += _shake_vector
	
	if lock_y_rotation:
		rotation.y = 0.0
