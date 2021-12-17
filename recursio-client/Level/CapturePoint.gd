extends Spatial
class_name CapturePoint

var neutral_color_name = "neutral"
# TODO: better use main schema for all coloring?
var player_color_name = "player_main"
var enemy_color_name = "enemy_main"
var player_in_capture_color_name = "player_ghost_primary_accent"
var player_captured_color_name = "player_ghost_main"
var enemy_in_capture_color_name = "enemy_ghost_primary_accent"
var enemy_captured_color_name = "enemy_ghost_main"

onready var _progress = $Viewport/TextureProgress

var active = true
var player_id :=-1

var _capture_progress = 0
var _capturing_team = -1
var _captured_by = -1

var _local_player_inside := false
var _local_enemy_inside := false
var _local_ghost_inside := false
var _capture_speed
var _release_speed
var _recapture_speed


func _ready():
	player_id = get_tree().get_network_unique_id()
	var _error = $Area.connect("body_entered", self, "_on_body_entered") 
	_error = $Area.connect("body_exited", self, "_on_body_exited") 
	set_capturing_player(-1)
	_capture_speed = Constants.get_value("capture", "capture_speed")
	_release_speed = Constants.get_value("capture", "release_speed")
	_recapture_speed = Constants.get_value("capture", "recapture_speed")

func reset():
	ColorManager.color_object_by_property(neutral_color_name, $MeshInstance.material_override, "albedo_color")
	active = false
	_capture_progress = 0
	_capturing_team = -1
	_captured_by = -1
	_local_player_inside = false
	_local_enemy_inside = false
	_local_ghost_inside = false


func _on_body_entered(body):
	var character = body.get_parent()
	if character is Player:
		_local_player_inside = true
	if character is Enemy:
		_local_enemy_inside = true
	if character is Ghost:
		_local_ghost_inside = true


func _on_body_exited(body):
	var character = body.get_parent()
	if character is Player:
		_local_player_inside = false
	if character is Enemy:
		_local_enemy_inside = false
	if character is Ghost:
		_local_ghost_inside = false


func _process(delta):
	if not active:
		return
	
	#cannot reach 1 on client only
	var local_maxima = 0.95 if _capture_progress <= 0.95 else _capture_progress
	
	#cannot reach 0 on client only
	var local_minima = 0.05 if _capture_progress >= 0.05 else _capture_progress
	if _local_player_inside or _local_ghost_inside:
		if _capturing_team == -1:
			set_capturing_player(player_id)
		elif _capturing_team == player_id:
			_capture_progress = min(local_maxima, _capture_progress + delta * _capture_speed)
		else:
			_capture_progress = max(local_minima, _capture_progress - delta * _recapture_speed)

	if _local_enemy_inside:
		if _capturing_team == -1:
			#using anything different from player_id because it doesnt really matter for visual purposes
			set_capturing_player(player_id + 1)
		elif _capturing_team != player_id:
			_capture_progress = min(local_maxima, _capture_progress + delta * _capture_speed)
		else:
			_capture_progress = max(local_minima, _capture_progress - delta * _recapture_speed)
	
	#TODO: for some reason this decreases when an enemy ghost should be standing on the point
	if not _local_player_inside and not _local_enemy_inside and not _local_ghost_inside:
		#_capture_progress = max(local_minima, _capture_progress - delta * _release_speed)
		pass

func capture(capturing_player_id):
	_captured_by = capturing_player_id
	_capture_progress = 1
	if capturing_player_id == player_id:
		ColorManager.color_object_by_property(player_captured_color_name, $MeshInstance.material_override, "albedo_color")
		Logger.info("I captured a point", "capture_point")
	else:
		ColorManager.color_object_by_property(enemy_captured_color_name, $MeshInstance.material_override, "albedo_color")
		Logger.info("Enemy captured a point", "capture_point")

func set_capturing_player(capturing_player_id):
	_capturing_team = capturing_player_id
	if capturing_player_id == -1:
		ColorManager.color_object_by_property(neutral_color_name, $MeshInstance.material_override, "albedo_color")
		ColorManager.color_object_by_property(neutral_color_name, _progress, "tint_progress")
	elif capturing_player_id == player_id:
		ColorManager.color_object_by_property(player_in_capture_color_name, $MeshInstance.material_override, "albedo_color")
		ColorManager.color_object_by_property(player_color_name,_progress, "tint_progress")
	else:
		ColorManager.color_object_by_property(enemy_in_capture_color_name, $MeshInstance.material_override, "albedo_color")
		ColorManager.color_object_by_property(enemy_color_name, _progress, "tint_progress")
	
func set_capture_status(capturing_player_id, capture_progress):
	Logger.info("Capture progress of " + str(capture_progress) + " received", "capture_point")
	_capture_progress = capture_progress
	_capturing_team = capturing_player_id

	_progress.value = _capture_progress
	$CaptureSound.unit_size = _capture_progress * 5.0

func capture_lost(capturing_player_id):
	_captured_by = -1
	if capturing_player_id == player_id:
		ColorManager.color_object_by_property(player_in_capture_color_name, $MeshInstance.material_override, "albedo_color")
		Logger.info("I lost a capture point", "capture_point")
	else:
		ColorManager.color_object_by_property(enemy_in_capture_color_name, $MeshInstance.material_override, "albedo_color")
		Logger.info("Enemy lost a capture point", "capture_point")

func get_capture_progress():
	return _capture_progress

func get_capture_team():
	return _capturing_team
