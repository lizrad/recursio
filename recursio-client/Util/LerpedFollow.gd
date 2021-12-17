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


func stop_following():
	_following = false


func start_following():
	_following = true
	set_physics_process(true)


func start_shake(amount: float, speed: float):
	var _error = _tween.connect("tween_all_completed", self, "_on_shake_complete")
	_shake_amount = amount
	_shake_speed = speed
	_on_shake_complete()


func _start_shake_tween(start_vector: Vector3, goal_vector: Vector3):
	_tween.remove_all()
	var time = 1.0/_shake_speed
	print(time)
	_tween.interpolate_property(self,"_shake_vector", start_vector, goal_vector, time, Tween.TRANS_LINEAR, Tween.EASE_IN)
	_tween.start()


func _on_shake_complete():
	print("_on_shake_complete")
	var start_vector = Vector3(_shake_vector.x, 0, _shake_vector.z)
	var goal_vector = Vector3(rand_range(-_shake_amount,_shake_amount),0,rand_range(-_shake_amount,_shake_amount))
	_start_shake_tween(start_vector, goal_vector)


func stop_shake():
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
