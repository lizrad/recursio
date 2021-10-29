extends PlayerBase
class_name Player

onready var _hud: HUD = get_node("HUD")

onready var _light_viewport = get_node("LightViewport")
onready var _overview_light = get_node("TransformReset/OverviewLight")
onready var _overview_target = get_node("TransformReset/OverviewTarget")
onready var _lerped_follow: LerpedFollow = get_node("TransformReset/LerpedFollow")
onready var _view_target = get_node("ViewTarget")

onready var _button_overlay: ButtonOverlay = get_node("ButtonOverlay")

# OVERRIDE #
func reset() -> void:
	.reset()
	_hud.reset()


func get_visibility_mask():
	return _light_viewport.get_texture()


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


func update_capture_point_hud(capture_points: Array) -> void:
	var index: int = 0
	for capture_point in capture_points:
		_hud.update_capture_point(index, capture_point.get_capture_progress(), capture_point.get_capture_team())
		index += 1


func show_round_start_hud(round_index, latency) -> void:
	_hud.round_start(round_index, latency)


func show_latency_delay_hud() -> void:
	_hud.latency_delay_phase_start()


func show_preparation_hud(round_index: int) -> void:
	_hud.prep_phase_start(round_index)
	_button_overlay.show_buttons("ready", ButtonOverlay.BUTTONS.RIGHT, true)


func show_countdown_hud() -> void:
	_hud.countdown_phase_start()
	_button_overlay.hide_buttons()


func show_game_hud(round_index) -> void:
	_hud.game_phase_start(round_index)




