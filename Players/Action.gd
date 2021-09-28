class_name Action
# TODO: need Spatial dependency only for get_tree() -> could access in another way?
#extends Resource
extends Spatial

export var ammunition: int
export var max_ammo: int
export var cooldown: float
export var recharge_time: float
export var enabled: bool
export var blocked: bool

# TODO: move into attack type
#export var attack_range: float
#export var damage: float
#export (PackedScene) var attack

#enum AttackTypeType {NORMAL, RESET}
#export (AttackTypeType) var attack_type_type

#export var charge_object: PackedScene
#export var move_while_charging: float
#export var rotate_while_charging: float

export (AudioStreamSample) var sound
export (StreamTexture) var img_bullet
export (PackedScene) var player_accessory

# dashing -> TODO: move to implementing class for interface
var time_since_dash_start := 0.0
var initial_dash_burst := Constants.dash_impulse
var dash_exponent := Constants.dash_exponent

signal ammunition_changed


func _init(ammo : int, cd : float, charge : float):
	ammunition = ammo
	max_ammo = ammunition
	cooldown = cd
	recharge_time = charge

func activate() -> void:

	if blocked:
		return

	if ammunition < 0:
		print("activate Action without ammo")
	elif ammunition > 0:
		print("activate Action with remaining ammo: ", ammunition)
	else:
		print("no remaining ammunition")
		return

	# block spaming
	blocked = true
	
	if sound:
		print("TODO: play attached action sound...")
	
	# TODO: fire actual action -> maybe as class hierarchy?
	print("TODO: fire actual action...")

	if ammunition > 0:
		ammunition -= 1
		emit_signal("ammunition_changed", ammunition)

	# re-enable
	if cooldown > 0:
		#SceneTree.create_timer(cooldown, "timeout")
		yield(get_tree().create_timer(cooldown), "timeout")
		blocked = false

	# refill ammu
	if recharge_time > 0 and ammunition < max_ammo:
		yield(get_tree().create_timer(recharge_time), "timeout")
		ammunition += 1
		emit_signal("ammunition_changed", ammunition)

	# TODO: implement class hierarchy with different activate implementations
#	if Input.is_action_pressed("player_dash"):
#		var e_section = max(
#			exp(log(initial_dash_burst - 1 / dash_exponent * time_since_dash_start)),
#			0.0
#		)
#		velocity += movement_input_vector * e_section
#		if time_since_dash_start == 0: 
#			print("TODO: play dash sound...")
#			#$DashSound.play()
#		time_since_dash_start += delta
#	else:
#		if time_since_dash_start > dash_cooldown:
#			time_since_dash_start = 0.0
#		elif time_since_dash_start != 0.0:
#			time_since_dash_start += delta

	# TODO: dash ui
	#var progress = time_since_dash_start / dash_cooldown
	#_player_hud.set_dash_progress(1.0 if progress == 0.0 else progress)
