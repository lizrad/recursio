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
export var activation_time: int  # ts in ticks when the action was initially triggered
export var activation_max: int  # max time in ticks where action can be applied

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

export var attack: PackedScene

# dashing -> TODO: move to implementing class for interface
var time_since_dash_start := 0.0
var initial_dash_burst = Constants.get_value("dash", "impulse")
var dash_exponent = Constants.get_value("dash", "exponent")

signal ammunition_changed
signal action_triggered
signal action_released


func _init(ammo: int, cd: float, charge: float, act_max: int):
	ammunition = ammo
	max_ammo = ammunition
	cooldown = cd
	recharge_time = charge
	activation_max = act_max


func set_active(value: bool) -> void:
	Logger.debug("Action set active for value: " + str(value), "actions")

	if not value:
		activation_time = 0
		emit_signal("action_released")
		return

	if blocked:
		return

	if ammunition < 0:
		# This action does not use ammo
		pass
	elif ammunition > 0:
		Logger.info("Activate Action with remaining ammo: " + str(ammunition), "actions")
	else:
		# No ammo left
		return

	# block spaming
	blocked = true

	if sound:
		# TODO: play attached action sound...
		pass

	activation_time = OS.get_ticks_msec()
	# fire actual action -> TODO: maybe as class hierarchy?
	if attack:
		Logger.info("instancing new attack", "actions")
		var player = get_parent().player
		var spawn = attack.instance()
		spawn.initialize(player)
		#spawn.global_transform = global_transform
		spawn.global_transform.origin = player.global_transform.origin
		#player.add_child(spawn)
		get_tree().get_root().add_child(spawn);

		# TODO: if has recoil configured -> apply on player

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
