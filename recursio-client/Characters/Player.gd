extends PlayerBase
class_name Player

onready var _hud: HUD = get_node("HUD")


func update_weapon_type(weapon_action: Action) -> void:
	_hud.update_ammo_type(weapon_action)


func update_fire_action_ammo(amount: int) -> void:
	_hud.update_fire_action_ammo(amount)


func update_special_movement_ammo(amount: int) -> void:
	_hud.update_special_movement_ammo(amount)
