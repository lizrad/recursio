extends Control
class_name HUD

onready var _timer_pb: TextureProgress = get_node("Timer/TimerProgressBar")
onready var _phase = get_node("Timer/TimerProgressBar/Phase")
onready var _ammo_group: Control = get_node("Abilities/Weapon")
onready var _controller_shoot = get_node("Abilities/Weapon/ControllerButtonShoot")
onready var _ammo: Label= get_node("Abilities/Weapon/WeaponAmmo")
onready var _ammo_type_bg = get_node("Abilities/Weapon/WeaponTypeBG")
onready var _ammo_type = get_node("Abilities/Weapon/WeaponTypeBG/WeaponType")
onready var _melee_group: Control = get_node("Abilities/Melee")
onready var _controller_melee = get_node("Abilities/Melee/ControllerButtonMelee")
onready var _melee = get_node("Abilities/Melee/MeleeAmmo")
onready var _melee_bg = get_node("Abilities/Melee/AspectRatioContainer/MeleeTexture")
onready var _dash_group: Control = get_node("Abilities/Dash")
onready var _controller_dash = get_node("Abilities/Dash/ControllerButtonDash")
onready var _dash: Label = get_node("Abilities/Dash/DashAmmo")
onready var _dash_bg = get_node("Abilities/Dash/AspectRatioContainer/DashTextureProgress")
onready var _capture_point_hb = get_node("Timer/TimerProgressBar/CapturePoints")
onready var _ammo_type_animation = get_node("TextureRect")
onready var _tween = get_node("Tween")
onready var _dash_tween = get_node("Abilities/Dash/AspectRatioContainer/DashTextureProgress/Tween")

onready var tween_time := 1.5

var _round_manager

# Capture point HUD scene for dynamically initializing them
var _capture_point_scene = preload("res://UI/CapturePointHUD.tscn")

var _number_of_capture_points := 0
# Array of all capture points in the HUD
var _capture_points = []

# Array of all spawn points as Position3D with SpawnPoint as child
var _spawn_points = []

# tracks active value for DashTextureProgress
var _dashTweenTime := 0.0

enum {
	Latency_Delay,
	Prep_Phase,
	Game_Phase
}

var _custom_max_time: Dictionary = {}
var _max_time := -1.0


func add_custom_max_time(phase: String, time: float):
	_custom_max_time[phase] = time

func pass_round_manager(round_manager):
	_round_manager = round_manager


func _ready() -> void:

	var _error = 0
	if not _tween.is_connected("tween_all_completed", self, "_on_tween_completed"):
		_error = _tween.connect("tween_all_completed", self, "_on_tween_completed")

	if not _dash_tween.is_connected("tween_completed", self, "_on_dash_tween_completed"):
		_error = _dash_tween.connect("tween_completed", self, "_on_dash_tween_completed")

	_error = InputManager.connect("controller_changed", self, "_on_controller_changed")
	_on_controller_changed(InputManager.get_current_controller())
	reset()


func _on_controller_changed(controller) -> void:
	_controller_shoot.texture = load("res://Resources/Icons/" + controller + "/shoot.png")
	_controller_melee.texture = load("res://Resources/Icons/" + controller + "/melee.png")
	_controller_dash.texture = load("res://Resources/Icons/" + controller + "/dash.png")
	pass


func reset():
	_phase.text = "Waiting for game to start..."
	_max_time = -1.0
	_controller_shoot.hide()
	_ammo.hide()
	_ammo_type_bg.hide()
	_controller_melee.hide()
	_melee.hide()
	_melee_bg.hide()
	_controller_dash.hide()
	_dash.hide()
	_dash_bg.hide()


func _process(_delta):
	var val = _calculate_progress()
	_timer_pb.value = val
	var color_name
	if val < 0.15:
		color_name = "ui_error"
	elif val < 0.35:
		color_name = "ui_warning"
	else:
		color_name = "ui_ok"
	ColorManager.color_object_by_property(color_name, _timer_pb, "tint_progress")


# Calculates the remaining time and maps it between 0 and 1
func _calculate_progress() -> float:
	if _max_time <= 0:
		return 0.0

	return _round_manager.get_current_phase_time_left() / 1000.0 / _max_time

func toggle_trigger(trigger, value: bool) -> void:
	if trigger == ActionManager.Trigger.DEFAULT_ATTACK_START:
		_melee_group.visible = value
		pass
	elif trigger == ActionManager.Trigger.FIRE_START:
		_ammo_group.visible = value
		pass
	elif trigger == ActionManager.Trigger.SPECIAL_MOVEMENT_START:
		_dash_group.visible = value
		pass

func prep_phase_start(round_index) -> void:
	_phase.text = "Preparation Phase " + str(round_index + 1)
	var phase_string = "prep_phase_time"
	if _custom_max_time.has(phase_string):
		_max_time = _custom_max_time[phase_string]
	else:
		_max_time = Constants.get_value( "gameplay", phase_string)
	_controller_shoot.show()
	_ammo.show()
	_ammo_type_bg.show()
	_controller_melee.show()
	_melee.show()
	_melee_bg.show()
	_controller_dash.show()
	_dash.show()
	_dash_bg.show()

	# TODO: this should be set explicit from outside in dash actions
	update_special_movement_ammo(2)


func countdown_phase_start() -> void:
	_phase.text = "Get ready!"
	var phase_string = "countdown_phase_seconds"
	if _custom_max_time.has(phase_string):
		_max_time = _custom_max_time[phase_string]
	else:
		_max_time = Constants.get_value("gameplay", phase_string)

func game_phase_start(round_index) -> void:
	_phase.text = "Game Phase " + str(round_index + 1)
	var phase_string = "game_phase_time"
	if _custom_max_time.has(phase_string):
		_max_time = _custom_max_time[phase_string]
	else:
		_max_time = Constants.get_value("gameplay", phase_string)


func update_fire_action_ammo(amount: int) -> void:
	Logger.info("Set fire ammo to: " + str(amount), "HUD")
	_ammo.text = str(amount)

	# mark ammo ui red -> is reset to weapon depending color in update_weapon_type
	if amount < 1:
		var color_name = "ui_error"
		ColorManager.color_object_by_property(color_name, _ammo, "custom_colors/font_color")
		ColorManager.color_object_by_property(color_name, _ammo_type_bg, "modulate")

	# only don't interfere with other animations
	if not $AnimationShoot.is_playing() or $AnimationShoot.current_animation == "sub_ammo":
		$AnimationShoot.stop()
		$AnimationShoot.play("sub_ammo")


func update_special_movement_ammo(amount: int) -> void:
	Logger.info("Set special movement ammo to: " + str(amount), "HUD")
	var cur_amount = int(_dash.text)
	if cur_amount != amount:
		var color_name = "ui_ok" if amount > 0 else "ui_error"
		var animation = "add_dash" if amount > cur_amount else "sub_dash"
		ColorManager.color_object_by_property(color_name, _dash, "custom_colors/font_color")
		_dash.text = str(amount)

		# just override current animation
		$AnimationDash.stop()
		$AnimationDash.play(animation)

		# TODO: should get max dash ammo from constants or action manager
		# color textureprogress depending on dash amount
		# amount 	under 	progress
		#	0		red		gray
		#	1		gray	white
		color_name = "ui_error" if amount < 1 else "ui_ok" if amount > 1 else "unselected"
		_dash_bg.tint_under = Color(UserSettings.get_setting("colors", color_name))
		color_name = "unselected" if amount < 1 else "ui_ok"
		_dash_bg.tint_progress = Color(UserSettings.get_setting("colors", color_name))

		if amount < 2:
			# only trigger for consuming dash
			if amount < cur_amount:
				if not _dash_tween.is_active():
					_dash_tween.interpolate_property(_dash_bg, "value", 0, 100, 5, Tween.TRANS_LINEAR)
					_dash_tween.start()
				else:
					_dashTweenTime = _dash_tween.tell()
		else:
			_dash_tween.stop_all()
			_dash_bg.value = 100


func update_weapon_type(max_ammo, img_bullet, color_name: String) -> void:
	Logger.info("Update ammo type", "HUD")
	ColorManager.color_object_by_property("ui_ok", _ammo, "custom_colors/font_color")
	ColorManager.color_object_by_property(color_name, _ammo_type_bg, "modulate")
	_ammo_type.texture = img_bullet
	_ammo.text = str(max_ammo)


func activate_spawn_point(timeline_index) -> void:
	Logger.info("Activate SpawnPoint " + str(timeline_index), "HUD")
	for spawn_point in _spawn_points:
		if spawn_point.has_node("SpawnPoint"):
			spawn_point.get_node("SpawnPoint").set_active(spawn_point.get_index() == timeline_index)


# Sets the internal player id for the capture points
func set_player_id(player_id) -> void:
	for capture_point in _capture_points:
		capture_point.set_player_id(player_id)


# Sets the internal player teamid for the capture points
func set_player_team_id(team_id) -> void:
	for capture_point in _capture_points:
		capture_point.set_player_team_id(team_id)


# Adds a new capture point HUD item to the HUD
func add_capture_point() -> void:
	var capture_point: CapturePointHUD = _capture_point_scene.instance()
	_capture_point_hb.add_child(capture_point)
	_capture_points.append(capture_point)

	# Convert number to letter
	var capture_point_name = char(65 + _number_of_capture_points)
	capture_point.set_name(capture_point_name)

	_number_of_capture_points += 1


# Sets the capture point progress of the specified capture point
# The progress is between 0 and 1
func update_capture_point(capture_point_id, progress, team) -> void:
	_capture_points[capture_point_id].update_status(progress, team)


func set_spawn_points(spawn_points):
	_spawn_points = spawn_points


func get_active_spawn_point() -> SpawnPoint:
	for spawn_point in _spawn_points:
		if spawn_point.has_node("SpawnPoint"):
			var spawn = spawn_point.get_node("SpawnPoint") as SpawnPoint
			if spawn.active:
				return spawn

	return null


# visual effect for showing insufficient ammo
# TODO: apply for dash too?
func wobble_ammo() -> void:
	if not $AnimationShoot.is_playing():
		$AnimationShoot.play("no_ammo")


func animate_weapon_selection(pos: Vector2) -> void:
	# if the weapon is currently toggled off do nothing
	if not _ammo_group.visible: 
		return
	if _tween.is_active():
		Logger.info("not restarting tween", "Tween")
		return

	_ammo_type_animation.texture = _ammo_type.texture
	_ammo_type_animation.visible = true
	Logger.info("starting tween", "Tween")
	var size = _ammo_type_animation.rect_size/2
	_tween.interpolate_property(_ammo_type_animation, "rect_position", pos - size, _ammo_type.rect_global_position - size/2, tween_time, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	_tween.interpolate_property(_ammo_type_animation, "rect_scale", Vector2.ONE, Vector2(0.25, 0.25), 2*tween_time, Tween.TRANS_LINEAR)
	_tween.interpolate_property(_ammo_type_animation, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1.5*tween_time, Tween.TRANS_LINEAR)
	_tween.start()


func _on_tween_completed() -> void:
	if not $AnimationShoot.is_playing():
		$AnimationShoot.play("select_weapon")


func _on_dash_tween_completed(_object: Object, _key: NodePath) -> void:
	if _dashTweenTime > 0:
		var dashTweenTime = 5 + _dashTweenTime - _dash_tween.get_runtime()
		_dashTweenTime = 0

		# something is wrong here...
		# maybe remove/stop_all() to get rid of existing tweens?
		_dash_tween.stop_all()
		_dash_tween.remove_all()

		var dashProgress = int((5 - dashTweenTime) / 5 * 100)
		_dash_tween.interpolate_property(_dash_bg, "value", dashProgress, 100, dashTweenTime, Tween.TRANS_LINEAR)
		_dash_tween.start()

