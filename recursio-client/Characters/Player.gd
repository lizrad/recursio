extends PlayerBase
class_name Player

signal initialized()

onready var _hud: HUD = get_node("KinematicBody/HUD")
onready var _light_viewport = get_node("KinematicBody/LightViewport")
onready var _overview_light = get_node("KinematicBody/TransformReset/OverviewLight")
onready var _overview_target = get_node("KinematicBody/TransformReset/OverviewTarget")
onready var _lerped_follow: LerpedFollow = get_node("KinematicBody/AsciiViewportContainer/Viewport/LerpedFollow")
onready var _view_target = get_node("KinematicBody/ViewTarget")
onready var _visibility_light = get_node("KinematicBody/VisibilityLight")
onready var _button_overlay: ButtonOverlay = get_node("KinematicBody/ButtonOverlay")
onready var _aim_visuals = get_node("KinematicBody/AimVisuals")
onready var _audio_player: AudioStreamPlayer = get_node("AudioStreamPlayer")
onready var _camera_shake_amount = Constants.get_value("vfx","camera_shake_amount")
onready var _camera_shake_speed  = Constants.get_value("vfx","camera_shake_speed")


var block_switching: bool = false


var _walls = []
var _past_frames = {}
var _just_corrected = false
var _last_server_position
var _last_server_time
var _round_manager

class MovementFrame:
	var position: Vector3 = Vector3.ZERO


func player_init(action_manager, round_manager) -> void:
	.player_base_init(action_manager)
	_round_manager = round_manager
	_hud.pass_round_manager(_round_manager)
	emit_signal("initialized")


func set_visibility_visualization_visible(is_visible):
	$KinematicBody/VisibilityVisualization.set_visible(is_visible)


func set_visibility_visualization_enemy_positions(enemy_positions: Array):
	$KinematicBody/VisibilityVisualization.set_looking_at_positions(enemy_positions)


# OVERRIDE #
func reset() -> void:
	set_visibility_visualization_visible(false)
	.reset()
	clear_past_frames()
	_hud.reset()


func reset_aim_mode():
	aim_mode = false
	if _aim_visuals.visible:
		_aim_visuals.visible = false
		for child in _aim_visuals.get_children():
			child.visible = false

func clear_past_frames():
	_past_frames.clear()


func clear_walls():
	_walls.clear()


# OVERRIDE #
func apply_input(movement_vector: Vector3, rotation_vector: Vector3, buttons: int) -> void:
	.apply_input(movement_vector, rotation_vector, buttons)
	if _just_corrected:
		clear_past_frames()
		_just_corrected = false
	else:
		var frame = MovementFrame.new()
		frame.position = self.position
		_past_frames[Server.get_server_time()] = frame

	# Nothing to do if player can't move
	if block_movement or currently_dying or currently_spawning:
		return

	# visual appearance for aim_mode
	# TODO: update drag_factor
	# _drag_factor = 2*Constants.get_value("movement", "drag_factor") -> needs to be updated also on server
	if aim_mode && !block_input:
		var action = _get_action(ActionManager.Trigger.FIRE_START, timeline_index) as Action
		if action.ammunition > 0:
			_aim_visuals.visible = true
			_aim_visuals.get_child(timeline_index % 2).visible = aim_mode
		else:
			# -> already handles sound effects but fail sound for no ammo is only needed for current player
			if not _audio_player.playing:
				_audio_player.play()
				_hud.wobble_ammo()
	else:
		reset_aim_mode()


# OVERRIDE #
# Always returns the same Action instance for the same trigger and timeline index. This preserves ammo count etc.
func _get_action(trigger, timeline_index):
	var id = timeline_index * 10 + trigger

	# Cache the action if it hasn't been cached yet
	if not _actions.has(id):
		var action = _action_manager.create_action_duplicate_for_trigger(trigger, timeline_index)
		_actions[id] = action
		if trigger == ActionManager.Trigger.SPECIAL_MOVEMENT_START:
			action.connect("ammunition_changed", self, "update_special_movement_ammo_hud")
		elif trigger == ActionManager.Trigger.FIRE_START:
			action.connect("ammunition_changed", self, "update_fire_action_ammo_hud")

	return _actions[id]


# OVERRIDE #
func wall_spawned(wall):
	_walls.append(wall)


func _on_wall_spawn_received(position, rotation, wall_index):
	if _walls.size()>wall_index:
		if _walls[wall_index]:
			Logger.info("correcting wall from " + str(_walls[wall_index].global_transform.origin) + " to "+ str(position), "wall_validation")
			_walls[wall_index].global_transform.origin = position
			#TODO: is rotation global here, could be dangerous if it isn't
			_walls[wall_index].rotation.y = rotation
	else:
		var wall_action_index = Constants.get_value("ghosts", "wall_placing_timeline_index")
		_action_manager.set_active(_get_action(ActionManager.Trigger.FIRE_START, wall_action_index) as Action, self, kb, get_parent())


# OVERRIDE #
func set_dying(new_dying_status: bool):
	.set_dying(new_dying_status)
	if currently_dying:
		PostProcess.glitch = true
		PostProcess.vignette = true
		PostProcess.animate_property("vignette_softness", 10, 1, _death_time)
		_visibility_light.toggle(false)
		_lerped_follow.stop_following()
		_lerped_follow.start_shake(_camera_shake_amount,_camera_shake_speed)


# OVERRIDE #
func set_spawning(new_spawning_status: bool):
	.set_spawning(new_spawning_status)
	if currently_spawning:
		PostProcess.glitch = false
		PostProcess.animate_property("vignette_softness", 1, 10, _spawn_time)
		_visibility_light.toggle(true)
		_lerped_follow.start_following()
		_lerped_follow.stop_shake()
	else:
		PostProcess.vignette = false

# OVERRIDE #
func non_vfx_spawn():
	.non_vfx_spawn()
	PostProcess.glitch = false
	PostProcess.vignette = false
	_visibility_light.toggle(true)
	_lerped_follow.start()
	_lerped_follow.stop_shake()

func get_visibility_mask():
	return _light_viewport.get_texture()


func set_overview_light_enabled(enabled):
	_overview_light.enabled = enabled


func set_custom_view_target(node):
	_lerped_follow.target = node


func move_camera_to_overview():
	_lerped_follow.target = _overview_target


func follow_camera():
	_lerped_follow.target = _view_target


func setup_capture_point_hud(number_of_capture_points) -> void:
	for i in number_of_capture_points:
		_hud.add_capture_point()
	_hud.set_player_id(self.player_id)


func setup_spawn_point_hud(spawn_points) -> void:
	_hud.set_spawn_points(spawn_points)


func update_weapon_type_hud(max_ammo, img_bullet, color_name: String) -> void:
	_hud.update_weapon_type(max_ammo, img_bullet, color_name)


func activate_spawn_point_hud(timeline_index) -> void:
	_hud.activate_spawn_point(timeline_index)


func update_fire_action_ammo_hud(amount: int) -> void:
	_hud.update_fire_action_ammo(amount)


func update_special_movement_ammo_hud(amount: int) -> void:
	_hud.update_special_movement_ammo(amount)


func update_capture_point_hud(capture_points: Array) -> void:
	var index: int = 0
	for capture_point in capture_points:
		_hud.update_capture_point(index, capture_point.get_capture_progress(), capture_point.get_capture_team())
		index += 1


func show_hud() -> void:
	_hud.show()


func hide_hud() -> void:
	_hud.hide()


func show_preparation_hud(round_index) -> void:
	_hud.prep_phase_start(round_index)
	_button_overlay.show_buttons(["ready!", "swap"], ButtonOverlay.BUTTONS.DOWN | ButtonOverlay.BUTTONS.RIGHT, ButtonOverlay.BUTTONS.DOWN)


func show_countdown_hud() -> void:
	# need to convert selected spawn point 3D coords to 2D screen space
	var active_spawn = _hud.get_active_spawn_point() as SpawnPoint
	if active_spawn:
		var camera = get_node("KinematicBody/NormalViewportContainer/Viewport/Camera")
		var pos = camera.unproject_position(active_spawn.global_transform.origin)
		_hud.animate_weapon_selection(pos)
	_hud.countdown_phase_start()
	_button_overlay.hide_buttons()


func show_game_hud(round_index) -> void:
	_hud.game_phase_start(round_index)


func get_button_overlay() -> ButtonOverlay:
	return _button_overlay


func handle_server_update(position, time):

	_last_server_position = position
	_last_server_time = time

	# Find the most fitting timestamp
	var time_with_data = time
	var closest_frame = null
	
	while not closest_frame:
		if _past_frames.has(time_with_data):
			closest_frame = _past_frames[time_with_data]
		else:
			time_with_data -= 1

		# Exit condition (e.g. for the first time)
		if time - time_with_data > 100:
			break

	if closest_frame:
		# Get value we had at that time
		var position_diff = position - closest_frame.position

		# If the difference is too large, correct it
		if position_diff.length() > 0.1 and _round_manager.get_current_phase() == RoundManager.Phases.GAME:
			# TODO: Lerp there rather than setting it outright
			var before = .get_position()
			self.position += position_diff

			Logger.info(("Corrected from " + str(before) + " to " + str(.get_position())
				+ " (should be at " + str(position) + " according to server)"), "movement_validation")
			Logger.warn("check if the TODOs in this block are still up to date (hotfix, lerp and correction) -> happens sometimes if switching timeline index very often")

			# Hotfix for overcompensation - we could also fix all following past states, but is that required?
			clear_past_frames()

			_just_corrected = true


func get_round_manager():
	return _round_manager


func toggle_visibility_light(value: bool):
	_visibility_light.toggle(value)


# OVERRIDE #
# Only emit signal for client
func hit(perpetrator):
	emit_signal("client_hit", perpetrator)


# call hit of baseclass triggered by server
func server_hit(perpetrator):
	.hit(perpetrator)
