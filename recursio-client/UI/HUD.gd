extends Control
class_name HUD

onready var _timer_pb: TextureProgress = get_node("TimerProgressBar")
onready var _phase = get_node("TimerProgressBar/Phase")
onready var _ammo: Label= get_node("WeaponAmmo")
onready var _ammo_type_bg = get_node("WeaponAmmo/WeaponTypeBG")
onready var _ammo_type = get_node("WeaponAmmo/WeaponType")
onready var _dash: Label = get_node("DashAmmo")
onready var _capture_point_hb = get_node("TimerProgressBar/CapturePoints")
onready var _ammo_type_animation = get_node("TextureRect")

onready var tween_time := 1.5

var _round_manager

# Capture point HUD scene for dynamically initializing them
var _capture_point_scene = preload("res://UI/CapturePointHUD.tscn")

var _number_of_capture_points := 0
# Array of all capture points in the HUD
var _capture_points = []

# Array of all spawn points as Position3D with SpawnPoint as child
var _spawn_points = []

enum {
	Latency_Delay,
	Prep_Phase,
	Game_Phase
}

var _max_time := -1.0


func pass_round_manager(round_manager):
	_round_manager = round_manager


func _ready() -> void:
	if not $Tween.is_connected("tween_all_completed", self, "_on_tween_completed"):
		var _error = $Tween.connect("tween_all_completed", self, "_on_tween_completed")

	reset()


func reset():
	_phase.text = "Waiting for game to start..."
	_max_time = -1.0
	_dash.visible = false
	_ammo.visible = false


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


func prep_phase_start(round_index) -> void:
	_phase.text = "Preparation Phase " + str(round_index + 1)
	_max_time = Constants.get_value("gameplay", "prep_phase_time")
	_dash.visible = true
	_ammo.visible = true

	# TODO: this should be set explicit from outside in dash actions
	update_special_movement_ammo(2)


func countdown_phase_start() -> void:
	_phase.text = "Get ready!"
	_max_time = Constants.get_value("gameplay", "countdown_phase_seconds")


func game_phase_start(round_index) -> void:
	_phase.text = "Game Phase " + str(round_index + 1)
	_max_time = Constants.get_value("gameplay", "game_phase_time")


func update_fire_action_ammo(amount: int) -> void:
	Logger.info("Set fire ammo to: " + str(amount), "HUD")
	_ammo.text = str(amount)
	# mark ammo ui red -> is reset to weapon depending color in update_weapon_type
	if amount < 1:
		var color_name = "ui_error"
		ColorManager.color_object_by_property(color_name, _ammo, "custom_colors/font_color")
		ColorManager.color_object_by_property(color_name, _ammo_type_bg, "modulate")


func update_special_movement_ammo(amount: int) -> void:
	Logger.info("Set special movement ammo to: " + str(amount), "HUD")
	var color_name = "ui_ok" if amount > 0 else "ui_error"
	ColorManager.color_object_by_property(color_name, _dash, "custom_colors/font_color")
	ColorManager.color_object_by_property(color_name, _ammo_type_bg, "modulate")
	_dash.text = str(amount)


func update_weapon_type(img_bullet, color_name: String) -> void:
	Logger.info("Update ammo type", "HUD")
	ColorManager.color_object_by_property("ui_ok", _ammo, "custom_colors/font_color")
	ColorManager.color_object_by_property(color_name, _ammo_type_bg, "modulate")
	_ammo_type.texture = img_bullet


func activate_spawn_point(timeline_index) -> void:
	Logger.info("Activate SpawnPoint " + str(timeline_index), "HUD")
	for spawn_point in _spawn_points:
		if spawn_point.has_node("SpawnPoint"):
			spawn_point.get_node("SpawnPoint").set_active(spawn_point.get_index() == timeline_index)


# Sets the internal player id for the capture points
func set_player_id(player_id) -> void:
	for capture_point in _capture_points:
		capture_point.set_player_id(player_id)


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
# TODO: apply for dash too
func wobble_ammo() -> void:
	if not $AnimationPlayer.is_playing():
		$AnimationPlayer.play("no_ammo")


func animate_weapon_selection(pos: Vector2) -> void:
	if $Tween.is_active():
		Logger.info("not restarting tween", "Tween")
		return

	_ammo_type_animation.texture = _ammo_type.texture
	_ammo_type_animation.visible = true
	Logger.info("starting tween", "Tween")
	$Tween.interpolate_property(_ammo_type_animation, "rect_position", pos, _ammo_type.rect_global_position, tween_time, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	# TODO: is there a opacity for controls?
	$Tween.interpolate_property(_ammo_type_animation, "visible", true, false, 2*tween_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()


func _on_tween_completed() -> void:
	if not $AnimationPlayer.is_playing():
		$AnimationPlayer.play("select_weapon")
