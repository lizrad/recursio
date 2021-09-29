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
export var activation_time: int # ts in ticks when the action was initially triggered
export var activation_max: int # max time in ticks where action can be applied

# TODO: move into attack type
#export var attack_range: float
#export var damage: float
#export (PackedScene) var attack

#enum AttackTypeType {NORMAL, RESET}
#export (AttackTypeType) var attack_type_type

#export var charge_object: PackedScene
#export var move_while_charging: float
#export var rotate_while_charging: float

export(AudioStreamSample) var sound
export(StreamTexture) var img_bullet
export(PackedScene) var player_accessory

# dashing -> TODO: move to implementing class for interface
var time_since_dash_start := 0.0
var initial_dash_burst := Constants.dash_impulse
var dash_exponent := Constants.dash_exponent

signal ammunition_changed
signal action_triggered
signal action_released


func _init(ammo : int, cd : float, charge : float, act_max : int):

	ammunition = ammo
	max_ammo = ammunition
	cooldown = cd
	recharge_time = charge
	activation_max = act_max


func set_active(value : bool) -> void:

	#print("set activate for value: ", value)
	if not value:
		activation_time = 0
		emit_signal("action_released")
		return

	if blocked:
		return

	if ammunition < 0:
		#print("activate Action without ammo")
		pass
	elif ammunition > 0:
		print("activate Action with remaining ammo: ", ammunition)
	else:
		#print("no remaining ammunition")
		return

	# block spaming
	blocked = true

	if sound:
		print("TODO: play attached action sound...")
	
	activation_time = OS.get_ticks_msec()
	# fire actual action -> TODO: maybe as class hierarchy?
	emit_signal("action_triggered")

	if ammunition > 0:
		ammunition -= 1
		emit_signal("ammunition_changed", ammunition)

	# re-enable
	if cooldown > 0:
		yield(get_tree().create_timer(cooldown), "timeout")
		blocked = false

	# refill ammu
	if recharge_time > 0 and ammunition < max_ammo:
		yield(get_tree().create_timer(recharge_time), "timeout")
		ammunition += 1
		emit_signal("ammunition_changed", ammunition)
