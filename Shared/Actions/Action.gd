class_name Action
extends Resource

export var name: String
export var max_ammo: int
export var cooldown: float
export var recharge_time: float
export var activation_max: int # max time in ticks where action can be applied

export var player_accessory: PackedScene
export var attack: PackedScene

var ammunition: int
var blocked := false
var activation_time: int # ts in ticks when the action was initially triggered
var trigger_times: Array = []

#warning-ignore:unused_signal
signal ammunition_changed
#warning-ignore:unused_signal
signal action_triggered
#warning-ignore:unused_signal
signal action_released
