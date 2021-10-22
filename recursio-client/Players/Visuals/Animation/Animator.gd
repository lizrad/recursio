extends Node
#TODO:	./Shoot
#		./Idle
#		./Wall
#		./Dash
#		-Move
#		./Melee
#		-Death
#		-Spawn

onready var IdleAnimator  = get_node("../IdleAnimator")
onready var FireAnimator  = get_node("../FireAnimator")
onready var DashAnimator  = get_node("../DashAnimator")
onready var MeleeAnimator  = get_node("../MeleeAnimator")
onready var MoveAnimator  = get_node("../MoveAnimator")

var _firing = false
var _dashing = false
var _meleeing = false

var _debug_velocity = 0
func _process(delta):
	if Input.is_action_just_pressed("player_shoot"):
		FireAnimator.connect("animation_over", self, "stop_fire_animation")
		FireAnimator.start_animation(ActionManager.ActionType.HITSCAN)
		_firing = true
	
	if Input.is_action_just_pressed("player_dash"):
		DashAnimator.connect("animation_over", self, "stop_dash_animation")
		DashAnimator.start_animation()
		_dashing = true
	elif Input.is_action_just_released("player_dash"):
		DashAnimator.stop_animation()
	
	if Input.is_action_just_pressed("player_melee"):
		MeleeAnimator.connect("animation_over", self, "stop_melee_animation")
		MeleeAnimator.start_animation()
		_meleeing = true

	
	if Input.is_action_pressed("player_move_up"):
		if _debug_velocity == 0:
			MoveAnimator.start_animation()
		_debug_velocity += 0.01
		_debug_velocity = min(_debug_velocity, 3.5)
	else:
		if _debug_velocity != 0:
			if _debug_velocity - 0.01 <= 0:
				MoveAnimator.stop_animation()
		_debug_velocity -=0.01
		_debug_velocity = max(_debug_velocity, 0.0)
	MoveAnimator.set_velocity(_debug_velocity)
	var keyframes
	if _debug_velocity > 0:
		keyframes = MoveAnimator.get_keyframe(delta)
	else:
		keyframes = IdleAnimator.get_keyframe(delta)
	if _firing:
		keyframes = combine_keyframes(keyframes,FireAnimator.get_keyframe(delta),1)
	if _dashing:
		keyframes = combine_keyframes(keyframes,DashAnimator.get_keyframe(delta),1)
	if _meleeing:
		keyframes = combine_keyframes(keyframes,MeleeAnimator.get_keyframe(delta),1)
	_apply_keyframes(keyframes)


func stop_fire_animation():
	FireAnimator.disconnect("animation_over", self, "stop_fire_animation")
	_firing = false;

func stop_dash_animation():
	DashAnimator.disconnect("animation_over", self, "stop_dash_animation")
	_dashing = false;
	
func stop_melee_animation():
	DashAnimator.disconnect("animation_over", self, "stop_melee_animation")
	_meleeing = false;

func combine_keyframes(a,b,t):
	var keyframes = {}
	for part in a:
		if b.has(part):
			keyframes[part]=mix_keyframe(a[part],b[part],t)
		else:
			keyframes[part]=a[part];
	for part in b:
		if not a.has(part):
			keyframes[part]=b[part]
	return keyframes

func mix_keyframe(a,b,t):
	t = clamp(t,0,1)
	var euler = Vector3.ZERO
	var a_euler = a.basis.get_euler()
	var b_euler = b.basis.get_euler()
	euler.x = a_euler.x if b_euler.x==0 else (b_euler.x if a_euler.x == 0 else a_euler.x*(1-t)+b_euler.x*t)
	euler.y = a_euler.y if b_euler.y==0 else (b_euler.y if a_euler.y == 0 else a_euler.y*(1-t)+b_euler.y*t)
	euler.z = a_euler.z if b_euler.z==0 else (b_euler.z if a_euler.z == 0 else a_euler.z*(1-t)+b_euler.z*t)
	var origin = Vector3.ZERO
	var a_origin = a.origin
	var b_origin = b.origin
	origin.x = a_origin.x if b_origin.x==0 else (b_origin.x if a_origin.x == 0 else a_origin.x*(1-t)+b_origin.x*t)
	origin.y = a_origin.y if b_origin.y==0 else (b_origin.y if a_origin.y == 0 else a_origin.y*(1-t)+b_origin.y*t)
	origin.z = a_origin.z if b_origin.z==0 else (b_origin.z if a_origin.z == 0 else a_origin.z*(1-t)+b_origin.z*t)
	
	var keyframe = Transform(
		Basis(euler),
			origin)
	
	var scale = Vector3.ZERO
	var a_scale = a.basis.get_scale()
	var b_scale = b.basis.get_scale()
	scale.x = a_scale.x if b_scale.x==1 else (b_scale.x if a_scale.x == 1 else a_scale.x*(1-t)+b_scale.x*t)
	scale.y = a_scale.y if b_scale.y==1 else (b_scale.y if a_scale.y == 1 else a_scale.y*(1-t)+b_scale.y*t)
	scale.z = a_scale.z if b_scale.z==1 else (b_scale.z if a_scale.z == 1 else a_scale.z*(1-t)+b_scale.z*t)
	
	keyframe.basis = keyframe.basis.scaled(scale)
	return keyframe

func _apply_keyframes(key_frames):
	for part in key_frames:
		part.transform = key_frames[part]
