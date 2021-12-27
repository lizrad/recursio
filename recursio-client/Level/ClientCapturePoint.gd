extends BaseCapturePoint
class_name ClientCapturePoint


onready var _progress = $Viewport/TextureProgress


var server_driven: bool = true

var player_team_id :int = -1
var neutral_color_name = "neutral"
# TODO: better use main schema for all coloring?
var player_color_name = "player_main"
var enemy_color_name = "enemy_main"
var player_in_capture_color_name = "player_ghost_primary_accent"
var player_captured_color_name = "player_ghost_main"
var enemy_in_capture_color_name = "enemy_ghost_primary_accent"
var enemy_captured_color_name = "enemy_ghost_main"


func apply_server_capture_gained(capturing_player_team_id: int)  -> void:
	current_owning_team = capturing_player_team_id
	capture_progress = 1
	_update_media()


func apply_server_capturer_switched(capturing_player_team_id: int)  -> void:
	_current_progress_team = capturing_player_team_id
	_update_media()


func apply_server_capture_progress_changed(capturing_player_team_id: int, new_capture_progress: float)  -> void:
	capture_progress = new_capture_progress
	_current_progress_team = capturing_player_team_id
	_progress.value = capture_progress
	_update_media()


func apply_server_capture_lost() -> void:
	current_owning_team = -1
	_update_media()


func get_capture_progress() -> float:
	return capture_progress


func get_progress_team() -> int:
	return _current_progress_team


# OVERRIDE #
func reset() -> void:
	.reset()
	_update_media()


# OVERRIDE #
func _change_capture_progress(progress: float) -> void:
	if (progress < 0.95 and progress > 0.05) or not server_driven:
		._change_capture_progress(progress)
		_update_media()


# OVERRIDE #
func _lose_capture() -> void:
	if not server_driven:
		._lose_capture()
		_update_media()


# OVERRIDE #
func _gain_capture(new_owning_team: int) -> void:
	if not server_driven:
		._gain_capture(new_owning_team)
		_update_media()


# OVERRIDE #
func _switch_capturer(new_progress_team: int) -> void:
	if not server_driven:
		._switch_capturer(new_progress_team)
		_update_media()


func _update_media() -> void:
	if current_owning_team != -1:
		if current_owning_team == player_team_id:
			ColorManager.color_object_by_property(player_captured_color_name, $MeshInstance.material_override, "albedo_color")
		else:
			ColorManager.color_object_by_property(enemy_captured_color_name, $MeshInstance.material_override, "albedo_color")
	else:
		if _current_progress_team == -1:
			ColorManager.color_object_by_property(neutral_color_name, $MeshInstance.material_override, "albedo_color")
			ColorManager.color_object_by_property(neutral_color_name, _progress, "tint_progress")
		elif _current_progress_team == player_team_id:
			ColorManager.color_object_by_property(player_in_capture_color_name, $MeshInstance.material_override, "albedo_color")
			ColorManager.color_object_by_property(player_color_name,_progress, "tint_progress")
		else:
			ColorManager.color_object_by_property(enemy_in_capture_color_name, $MeshInstance.material_override, "albedo_color")
			ColorManager.color_object_by_property(enemy_color_name, _progress, "tint_progress")
	$CaptureSound.unit_size = capture_progress * 5.0
