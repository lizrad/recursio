class_name Action
extends Resource

export var name: String
export var max_ammo: int
export var cooldown: float
export var recharge_time: float
export var activation_max: int # max time in ticks where action can be applied

export var sound: AudioStreamSample
export var img_bullet: StreamTexture
export var img_bullet_bg: StreamTexture
export var player_accessory: PackedScene
export var attack: PackedScene

var ammunition 
var blocked := false
var activation_time: int # ts in ticks when the action was initially triggered
var trigger_times: Array = []

signal ammunition_changed
signal action_triggered
signal action_released
