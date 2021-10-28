extends PlayerBase
class_name Player

onready var _hud: HUD = get_node("HUD")

onready var _light_viewport = get_node("LightViewport")
onready var _overview_light = get_node("TransformReset/OverviewLight")
onready var _overview_target = get_node("TransformReset/OverviewTarget")
onready var _lerped_follow: LerpedFollow = get_node("TransformReset/LerpedFollow")
onready var _view_target = get_node("ViewTarget")

func get_visibility_mask():
	return _light_viewport.get_texture()


func reset():
	block_movement = true
	_hud.reset()

func move_back_to_spawnpoint():
	Logger.info("Moving player back to spawnpoint at " + str(spawn_point), "spawnpoints")
	.set_position(spawn_point)


func set_overview_light_enabled(enabled):
	_overview_light.enabled = enabled


func move_camera_to_overview():
	_lerped_follow.target = _overview_target


func follow_camera():
	_lerped_follow.target = _view_target


func update_weapon_type(weapon_action: Action) -> void:
	_hud.update_ammo_type(weapon_action)


func update_fire_action_ammo(amount: int) -> void:
	_hud.update_fire_action_ammo(amount)


func update_special_movement_ammo(amount: int) -> void:
	_hud.update_special_movement_ammo(amount)
