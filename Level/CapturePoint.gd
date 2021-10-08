extends Spatial

var _capture_progress = 0
var _capturing_team = -1
var _captured_by = -1
var player_id :=-1

var _local_player_inside := false
var _local_enemy_inside := false
var _capture_speed
var _release_speed
var _recapture_speed
var _capture_time

func _ready():
	player_id = get_tree().get_network_unique_id()
	$Area.connect("body_entered", self, "_on_body_entered")
	$Area.connect("body_exited", self, "_on_body_exited")
	set_capturing_player(-1)
	_capture_speed = Constants.get_value("capture", "capture_speed")
	_release_speed = Constants.get_value("capture", "release_speed")
	_recapture_speed = Constants.get_value("capture", "recapture_speed")
	_capture_time = Constants.get_value("capture", "capture_time")

func reset():
	_capture_progress = 0
	_capturing_team = -1
	_captured_by = -1
	player_id =-1
	_local_player_inside = false
	_local_enemy_inside = false
	
	
func _on_body_entered(body):
	if body is Player:
		_local_player_inside = true
	if body is Enemy:
		_local_enemy_inside = true


func _on_body_exited(body):
	if body is Player:
		_local_player_inside = false
	if body is Enemy:
		_local_enemy_inside = false


func _process(delta):
	var adjusted_delta = delta / _capture_time
	if _local_player_inside:
		if _capturing_team == -1:
			set_capturing_player(player_id)
		elif _capturing_team == player_id:
			#cannot reach 1 on client only
			_capture_progress = min(0.95, _capture_progress + adjusted_delta * _capture_speed)
			pass
		else:
			#cannot reach 0 on client only
			_capture_progress = max(0.5, _capture_progress - adjusted_delta * _recapture_speed)
			pass
	
	if _local_enemy_inside:
		if _capturing_team == -1:
			#using anything differen from player_id because it doesnt really matter for visual purposes
			set_capturing_player(player_id+1)
		elif _capturing_team != player_id:
			#cannot reach 1 on client only
			_capture_progress = min(0.95, _capture_progress + adjusted_delta * _capture_speed)
			pass
		else:
			#cannot reach 0 on client only
			_capture_progress = max(0.5, _capture_progress - adjusted_delta * _recapture_speed)
			pass
			
	if not _local_player_inside and not _local_enemy_inside:
		#cannot reach 0 on client only
		_capture_progress = max(0, _capture_progress - adjusted_delta * _release_speed)
		pass

func capture(capturing_player_id):
	_captured_by = capturing_player_id
	_capture_progress = 1
	if capturing_player_id == player_id:
		$MeshInstance.material_override.albedo_color = Color.aquamarine
		Logger.info("I captured a point", "capture point")
	else:
		$MeshInstance.material_override.albedo_color = Color.deeppink
		Logger.info("Enemy captured a point", "capture point")

func set_capturing_player(capturing_player_id):
	_capturing_team = capturing_player_id
	if capturing_player_id == -1:
		$MeshInstance.material_override.albedo_color = Color.gray
	elif capturing_player_id == player_id:
		$MeshInstance.material_override.albedo_color = Color.green
	else:
		$MeshInstance.material_override.albedo_color = Color.red
	
func set_capture_status(capturing_player_id, capture_progress):
	_capture_progress = capture_progress

func capture_lost(capturing_player_id):
	_captured_by = -1
	if capturing_player_id == player_id:
		$MeshInstance.material_override.albedo_color = Color.green
		Logger.info("I captured a point", "capture point")
	else:
		$MeshInstance.material_override.albedo_color = Color.red
		Logger.info("Enemy captured a point", "capture point")

func get_capture_progress():
	return _capture_progress

func get_capture_team():
	return _capturing_team
