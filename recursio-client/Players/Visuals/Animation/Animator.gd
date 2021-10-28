extends BaseAnimator

#TODO:	./Idle
#		./Shoot
#		./Wall
#		./Dash
#		./Melee
#		./Move
#		./Turn
#		-Death
#		-Spawn

onready var idle_animator  = get_node("../IdleAnimator")
onready var turn_animator  = get_node("../TurnAnimator")
onready var move_animator  = get_node("../MoveAnimator")
onready var dash_animator  = get_node("../DashAnimator")
onready var hitscan_animator  = get_node("../HitscanAnimator")
onready var wall_animator  = get_node("../WallAnimator")
onready var melee_animator  = get_node("../MeleeAnimator")

var _animation_status = {}
var _action_animations = {}
var _priority_sorted = []

func _ready():
	_animation_status[idle_animator] = true
	_priority_sorted.append(idle_animator)
	_animation_status[turn_animator] = true
	_priority_sorted.append(turn_animator)
	_animation_status[move_animator] = false
	_priority_sorted.append(move_animator)
	
	_animation_status[dash_animator] = false
	_priority_sorted.append(dash_animator)
	
	_action_animations[ActionManager.ActionType.DASH] = dash_animator
	_animation_status[hitscan_animator] = false
	_priority_sorted.append(hitscan_animator)
	_action_animations[ActionManager.ActionType.HITSCAN] = hitscan_animator
	_animation_status[wall_animator] = false
	_priority_sorted.append(wall_animator)
	_action_animations[ActionManager.ActionType.WALL] = wall_animator
	_animation_status[melee_animator] = false
	_priority_sorted.append(melee_animator)
	_action_animations[ActionManager.ActionType.MELEE] = melee_animator

func action_status_changed(action_type, status):
	Logger.debug("Status of "+ str(action_type)+" changed to "+str(status), "animation")
	var animator = _action_animations[action_type]
	if status and not _animation_status[animator] :
		animator.connect("animation_over", self, "_stop_animation", [animator])
		animator.start_animation()
		_animation_status[animator] = true
	else:
		if animator.has_method("stop_animation"):
			animator.stop_animation()

func velocity_changed(velocity, front_vector, right_vector):
	#because movement only aproaches 0 asymptotically
	var epsilon = 0.000001
	var front_velocity = abs(front_vector.dot(velocity))
	front_velocity = 0 if abs(front_velocity)<epsilon else front_velocity
	var right_velocity = right_vector.dot(velocity)
	right_velocity = 0 if abs(right_velocity)<epsilon else right_velocity
	
	move_animator.set_velocity(front_velocity)
	if not _animation_status[move_animator] and front_velocity>0:
		_animation_status[move_animator]  = true
		move_animator.start_animation()
		move_animator.connect("animation_over", self, "_stop_animation",[move_animator])
	elif _animation_status[move_animator]  and front_velocity<=0:
		move_animator.stop_animation()
	turn_animator.set_velocity(right_velocity)

func _process(delta):
	_reset_keyframes()
	for animator in _priority_sorted:
		if _animation_status[animator]:
			_keyframes = combine_keyframes(_keyframes,animator.get_keyframe(delta),1)
	_apply_keyframes(_keyframes)

func _stop_animation(animator):
	animator.disconnect("animation_over", self, "_stop_animation")
	_animation_status[animator] = false

func combine_keyframes(a,b,t):
	var keyframes = {}
	if not a:
		return b
	if not b:
		return a
	for pivot in a:
		if b.has(pivot):
			keyframes[pivot]=mix_keyframe(pivot, a[pivot],b[pivot],t)
		else:
			keyframes[pivot]=a[pivot];
	for pivot in b:
		if not a.has(pivot):
			keyframes[pivot]=b[pivot]
	return keyframes

func mix_keyframe(pivot,a,b,t):
	t = clamp(t,0,1)
	var euler = Vector3.ZERO
	var a_euler = a.basis.get_euler()
	var b_euler = b.basis.get_euler()
	euler.x = a_euler.x if b_euler.x == _default_rotations[pivot].x else (b_euler.x if a_euler.x == _default_rotations[pivot].x else a_euler.x*(1-t)+b_euler.x*t)
	euler.y = a_euler.y if b_euler.y == _default_rotations[pivot].y else (b_euler.y if a_euler.y == _default_rotations[pivot].y else a_euler.y*(1-t)+b_euler.y*t)
	euler.z = a_euler.z if b_euler.z == _default_rotations[pivot].z else (b_euler.z if a_euler.z == _default_rotations[pivot].z else a_euler.z*(1-t)+b_euler.z*t)
	var origin = Vector3.ZERO
	var a_origin = a.origin
	var b_origin = b.origin
	origin.x = a_origin.x if b_origin.x == _default_positions[pivot].x else (b_origin.x if a_origin.x == _default_positions[pivot].x else a_origin.x*(1-t)+b_origin.x*t)
	origin.y = a_origin.y if b_origin.y == _default_positions[pivot].y else (b_origin.y if a_origin.y == _default_positions[pivot].y else a_origin.y*(1-t)+b_origin.y*t)
	origin.z = a_origin.z if b_origin.z == _default_positions[pivot].z else (b_origin.z if a_origin.z == _default_positions[pivot].z else a_origin.z*(1-t)+b_origin.z*t)

	
	var keyframe = Transform(
		Basis(euler),
			origin)
	
	var scale = Vector3.ZERO
	var a_scale = a.basis.get_scale()
	var b_scale = b.basis.get_scale()
	scale.x = a_scale.x if b_scale.x == _default_scales[pivot].x else (b_scale.x if a_scale.x == _default_scales[pivot].x else a_scale.x*(1-t)+b_scale.x*t)
	scale.y = a_scale.y if b_scale.y == _default_scales[pivot].y else (b_scale.y if a_scale.y == _default_scales[pivot].y else a_scale.y*(1-t)+b_scale.y*t)
	scale.z = a_scale.z if b_scale.z == _default_scales[pivot].z else (b_scale.z if a_scale.z == _default_scales[pivot].z else a_scale.z*(1-t)+b_scale.z*t)
	
	keyframe.basis = keyframe.basis.scaled(scale)
	return keyframe

func _apply_keyframes(key_frames):
	for part in key_frames:
		part.transform = key_frames[part]
