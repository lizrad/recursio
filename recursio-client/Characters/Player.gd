extends PlayerBase
class_name Player

onready var _hud: HUD = get_node("HUD")

func get_visibility_mask():
	return $LightViewport.get_texture()


func reset():
	block_movement = true
	_hud.reset()

func move_back_to_spawnpoint():
	Logger.info("Moving player back to spawnpoint at " + str(spawn_point), "spawnpoints")
	.set_position(spawn_point)


func set_overview_light_enabled(enabled):
	$TransformReset/OverviewLight.enabled = enabled


func move_camera_to_overview():
	$TransformReset/LerpedFollow.target = $TransformReset/OverviewTarget


func follow_camera():
	$TransformReset/LerpedFollow.target = $ViewTarget


func update_weapon_type(weapon_action: Action) -> void:
	_hud.update_ammo_type(weapon_action)


func update_fire_action_ammo(amount: int) -> void:
	_hud.update_fire_action_ammo(amount)


func update_special_movement_ammo(amount: int) -> void:
	_hud.update_special_movement_ammo(amount)
